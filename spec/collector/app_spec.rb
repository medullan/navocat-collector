require File.expand_path '../spec_helper.rb', __FILE__

# These examples have dependencies, and need to be run in order

describe "Collector Application" do

  token = '3423432423423423423423'
  member_id = '384739284793284293'
  dataset = nil
  profile_id = nil
  client_id = 'abcd1234abcd1234'

  before(:all) do
    dataset = Meda::Dataset.new('test', Meda.configuration)
    dataset.token = token
    dataset.default_profile_id = '471bb8f0593711e48c1e44fb42fffeaa'
    dataset.landing_pages = [/\/pilot\/landingpage/,/\/members\/myblue\/dashboard/]
    dataset.whitelisted_urls  = [/\/hra\/lobby\.aspx\?toolid=3563/,/\/web\/guest\/myblue\?.*Fcreate_account$/]
    dataset.enable_data_retrivals = true
    dataset.google_analytics = {
      'record' => true,
      'tracking_id' => 'UA-666-1',
      'custom_dimensions' => {}
    }
    dataset.filter_file_name = "HitFilter.rb"
    dataset.filter_class_name = "HitFilter"
    Meda.datasets[token] = dataset
  end

  after(:all) do
    Meda.datasets[token] = nil
  end

  describe 'index' do
    it 'says hello world' do
      get '/meda'
      last_response.should be_ok
    end
  end

  describe 'identify.json' do

    it 'identifies a new user' do
      post_data = {'dataset' => token, 'member_id' => member_id}
      post 'meda/identify.json', post_data.to_json, :content_type => 'application/json'
      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body['profile_id']).to be_present
      profile_id = body['profile_id']
    end

  end

  describe 'profile.json' do

    it 'posts profile info' do
      post_data = {'dataset' => token, 'profile_id' => profile_id, 'state' => 'Maine', 'weight' => '200'}
      post 'meda/profile.json', post_data.to_json, :content_type => 'application/json'
      expect(last_response).to be_ok
    end

  end

  describe 'profile.json' do

    it 'posts profile with bad profile_id' do
      post_data = {'dataset' => token, 'profile_id' => 'some-bad-profile-id', 'state' => 'Maine', 'weight' => '200'}
      post 'meda/profile.json', post_data.to_json, :content_type => 'application/json'
      expect(last_response).to be_bad_request
    end

  end

  describe 'getprofile.json' do

    it 'get profile info' do
      post_data = {'dataset' => token, 'profile_id' => profile_id}
      post 'meda/getprofile.json', post_data.to_json, :content_type => 'application/json' 
      body = JSON.parse(last_response.body)
      expect(body['state']).to be_present
      state = body['state']
      expect(state).to eq('Maine')
    end

  end


  describe 'getprofile.json' do

    it 'get profile info with bad profile_id' do
      post_data = {'dataset' => token, 'profile_id' => 'some-bad-profile-id'}
      post 'meda/getprofile.json', post_data.to_json, :content_type => 'application/json' 
      expect(last_response).to be_bad_request
    end

  end

  describe 'page.json' do

    context 'with missing client_id' do
      it 'responds with bad request' do
        post_data = {
          'dataset' => token, 'profile_id' => profile_id,
          'title' => 'foo', 'hostname' => 'http://www.example.com', 'path' => '/'
        }
        post 'meda/page.json', post_data.to_json, :content_type => 'application/json'
        app.settings.connection.join_threads

        expect(last_response).to be_bad_request
      end
    end

    context 'with dataset, profile_id, client_id, and page params' do
      it 'records the pageview' do
        post_data = {
          'dataset' => token, 'profile_id' => profile_id, 'client_id' => client_id,
          'title' => 'foo', 'hostname' => 'http://www.example.com', 'path' => '/'
        }
        post 'meda/page.json', post_data.to_json, :content_type => 'application/json'
        app.settings.connection.join_threads

        expect(last_response).to be_ok
        expect(dataset.last_hit).to be_present
        expect(dataset.last_disk_hit).to be_present
        path = dataset.last_disk_hit[:path]
        expect(File.read(path)).to match(dataset.last_disk_hit[:data])
        expect(dataset.last_ga_hit).to be_present
      end
    end

    context 'with explicit user_ip set' do
      it 'records a pageview with that IP de-identified' do
        post_data = {
          'dataset' => token, 'profile_id' => profile_id, 'client_id' => client_id,
          'title' => 'foo', 'hostname' => 'http://www.example.com', 'user_ip' => '123.123.123.123', 'path' => '/'
        }
        post 'meda/page.json', post_data.to_json, :content_type => 'application/json'
        expect(dataset.last_hit.props[:user_ip]).to eq('123.123.123.0')
      end
    end

    context 'with REMOTE_ADDR header' do
      it 'records a pageview with that IP de-identified' do
        post_data = {
          'dataset' => token, 'profile_id' => profile_id, 'client_id' => client_id,
          'title' => 'foo', 'hostname' => 'http://www.example.com', 'path' => '/'
        }
        post 'meda/page.json', post_data.to_json, { :content_type => 'application/json',
          'REMOTE_ADDR' => '123.123.123.123' }
        expect(dataset.last_hit.props[:user_ip]).to eq('123.123.123.0')
      end
    end

    context 'with X_FORWARDED_FOR header set by a proxy server' do
      it 'records a pageview with that IP de-identified' do
        post_data = {
          'dataset' => token, 'profile_id' => profile_id, 'client_id' => client_id,
          'title' => 'foo', 'hostname' => 'http://www.example.com', 'path' => '/'
        }
        post 'meda/page.json', post_data.to_json, { :content_type => 'application/json',
          'REMOTE_ADDR' => '1.2.3.4', 'HTTP_X_FORWARDED_FOR' => '123.123.123.123, boops' }

        expect(dataset.last_hit.props[:user_ip]).to eq('123.123.123.0')
      end
    end
  end

  describe 'track.json' do

    context 'with missing client_id' do
      it 'responds with bad request' do
        post_data = {
          'dataset' => token, 'client_id' => client_id,
          'category' => 'foo', 'action' => 'testing', 'label' => 'boop!', 'value' => '1', 'path' => '/'
        }
        post 'meda/track.json', post_data.to_json, :content_type => 'application/json'
        app.settings.connection.join_threads

        expect(last_response).to be_bad_request
      end
    end

    context 'with dataset, profile_id, client_id, and event params' do
      it 'records the event' do
        post_data = {
          'dataset' => token, 'profile_id' => profile_id, 'client_id' => client_id, 'path' => '/',
          'category' => 'foo', 'action' => 'testing', 'label' => 'boop!', 'value' => '1'
        }
        post 'meda/track.json', post_data.to_json, :content_type => 'application/json'
        app.settings.connection.join_threads

        expect(last_response).to be_ok
      end
    end
  end

  describe 'page.gif' do

    request_path = "meda/page.gif?dataset=#{token}&cb=2219723aea1b964fe9d8c23789a4eded757f&hostname=http%3A%2F%2Flocalhost&referrer=&path=%2Fweb%2Fguest%2Fmyblue%3Fp_p_id%3D58%26p_p_lifecycle%3D0%26p_p_state%3Dnormal%26p_p_mode%3Dview%26p_p_col_id%3Dcolumn-1%26p_p_col_count%3D1%26_58_struts_action%3D%252Flogin%252Fcreate_account&title=fepblue.org+-+Welcome&profile_id=471bb8f0593711e48c1e44fb42fffeaa&client_id=d43ce2c8d9daca4ddaca70d3d0957ca96113"
    unknown_path = "meda/page.gif?dataset=#{token}&cb=2219723aea1b964fe9d8c23789a4eded757f&hostname=http%3A%2F%2Flocalhost&referrer=&path=%2Fweb%2Fguest%2Fmyblue%3Fp_p_id%3D58%26p_p_lifecycle%3D0%26p_p_state%3Dnormal%26p_p_mode%3Dview%26p_p_col_id%3Dcolumn-1%26p_p_col_count%3D1%26_58_struts_action%3D%252Flogin%252Fcreate_account_random_ext&title=fepblue.org+-+Welcome&profile_id=471bb8f0593711e48c1e44fb42fffeaa&client_id=d43ce2c8d9daca4ddaca70d3d0957ca96113"
    
    context 'with qs params and path not in white-list' do
      it 'should return the path excluding query string params' do
        get unknown_path
        #app.settings.connection.join_threads
        expect(dataset.last_hit.props[:path]).to eq('/web/guest/myblue')
      end
    end

    context 'with qa params and path in white-list' do
      it 'should return a full path including query string params' do
        get request_path
        #app.settings.connection.join_threads
        expect(dataset.last_hit.props[:path]).to eq('/web/guest/myblue?p_p_id=58&p_p_lifecycle=0&p_p_state=normal&p_p_mode=view&p_p_col_id=column-1&p_p_col_count=1&_58_struts_action=%2Flogin%2Fcreate_account')
      end
    end

    context 'without qs params' do
      it 'should return the path specified' do
        get "meda/page.gif?dataset=#{token}&cb=2219723aea1b964fe9d8c23789a4eded757f&hostname=http%3A%2F%2Flocalhost&referrer=&path=%2Fweb%2Fguest%2Fmyblue&title=fepblue.org+-+Welcome&profile_id=471bb8f0593711e48c1e44fb42fffeaa&client_id=d43ce2c8d9daca4ddaca70d3d0957ca96113"
        #app.settings.connection.join_threads
        expect(dataset.last_hit.props[:path]).to eq('/web/guest/myblue')
      end
    end

    context 'without a path parameter' do
      it 'should return a bad request' do
        get request_path.sub! 'path', 'paths'
        expect(last_response).to be_bad_request
      end
    end
  end

end

