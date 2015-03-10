require File.expand_path '../spec_helper.rb', __FILE__

# These examples have dependencies, and need to be run in order

describe "Collector Application" do

  Meda.configuration.features = {}
  Meda.configuration.features["profile_store"] = "mapdb"

  store_config = {}
  store_config["config"] = Meda.configuration
  store_config["name"] = "testdb_#{rand(10000000)}"

  Meda.featuresNoCache

  test_increment = 1
  token = '3423432423423423423423'
  member_id = '384739284793284293'
  delete_member_id = 'AA84739284793284293'
  dataset = nil
  profile_id = nil
  delete_profile_id = nil
  client_id = 'abcd1234abcd1234'

  before(:all) do
    dataset = Meda::Dataset.new('test', Meda.configuration)
    dataset.token = token
    dataset.landing_pages = [/\/pilot\/landingpage/,/\/members\/myblue\/dashboard/]
    dataset.whitelisted_urls  = [/\/hra\/lobby\.aspx\?toolid=3563/,/\/web\/guest\/myblue\?.*Fcreate_account$/]
    dataset.enable_data_retrivals = true
    dataset.enable_profile_delete = true
    dataset.google_analytics = {
      'record' => true,
      'tracking_id' => 'UA-666-1',
      'custom_dimensions' => {}
    }

    Meda.datasets[token] = dataset
  end

  after(:all) do
    Meda.datasets[token] = nil
  end

  def setup_delete_profile_id(token,delete_member_id)
    post_data = {'dataset' => token, 'member_id' => delete_member_id}
    post 'meda/identify.json', post_data.to_json, :content_type => 'application/json'
    expect(last_response).to be_ok
    body = JSON.parse(last_response.body)
    expect(body['profile_id']).to be_present
    body['profile_id']
  end

  describe 'index' do
    it 'says hello world' do
      get '/meda'
      expect(last_response).to be_ok
    end
  end

  describe 'identify.json' do

    it 'identifies a new user' do
      post_data = {'dataset' => token, 'member_id' => member_id}
      post 'meda/identify.json', post_data.to_json, :content_type => 'application/json'
      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      profile_id = body['profile_id']
      expect(body['profile_id']).to be_present
      expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
    end

  end

  describe 'profile.json' do

    it 'posts profile info' do
      post_data = {'dataset' => token, 'profile_id' => profile_id, 'state' => 'Maine', 'weight' => '200'}
      post 'meda/profile.json', post_data.to_json, :content_type => 'application/json'
      expect(last_response).to be_ok
      expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
    end

    it 'posts profile with bad profile_id' do
      post_data = {'dataset' => token, 'profile_id' => 'some-bad-profile-id', 'state' => 'Maine', 'weight' => '200'}
      post 'meda/profile.json', post_data.to_json, :content_type => 'application/json'
      expect(last_response).to be_bad_request
      expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
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
      expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
    end

  end

  describe 'getprofile.json' do

    it 'get profile info with bad profile_id' do
      post_data = {'dataset' => token, 'profile_id' => 'some-bad-profile-id'}
      post 'meda/getprofile.json', post_data.to_json, :content_type => 'application/json' 
      expect(last_response).to be_bad_request
      expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
    end

  end


  describe 'delete_profile.json' do
    it 'delete profile' do
      test_increment += 1
      delete_member_id = Time.now.getutc.to_i + test_increment
      delete_profile_id = setup_delete_profile_id(token, delete_member_id)
      delete_data = {'dataset' => token, 'profile_id' => delete_profile_id}
      delete 'meda/profile.json', delete_data.to_json, :content_type => 'application/json'
      expect(last_response).to be_ok

      post_data = {'dataset' => token, 'profile_id' => delete_profile_id}
      post 'meda/getprofile.json', post_data.to_json, :content_type => 'application/json' 
      expect(last_response).to be_bad_request
      expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
    end

    it 'delete profile with bad id' do
      test_increment += 1
      delete_member_id = Time.now.getutc.to_i + test_increment
      delete_data = {'dataset' => token, 'profile_id' => 1}
      delete 'meda/profile.json', delete_data.to_json, :content_type => 'application/json'
      expect(last_response).to be_bad_request
      expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
    end

     it 'delete profile with toggle off' do
      dataset.enable_profile_delete = false
      test_increment += 100
      delete_member_id = Time.now.getutc.to_i + test_increment
      delete_profile_id = setup_delete_profile_id(token, delete_member_id)
      delete_data = {'dataset' => token, 'profile_id' => delete_profile_id}
      delete 'meda/profile.json', delete_data.to_json, :content_type => 'application/json'
      dataset.enable_profile_delete = true
      expect(last_response).to be_bad_request
      expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
    end
  end


  describe 'profile_delete.gif' do
    it 'delete profile' do
      test_increment += 1
      delete_member_id = Time.now.getutc.to_i + test_increment
      delete_profile_id = setup_delete_profile_id(token, delete_member_id)
      get "meda/profile_delete.gif?dataset=#{token}&profile_id=#{delete_profile_id}"
      expect(last_response).to be_ok
      expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
    end

    it 'delete profile with bad id' do
      delete_profile_id = 1 
      get "meda/profile_delete.gif?dataset=#{token}&profile_id=#{delete_profile_id}"
      expect(last_response).to be_bad_request
      expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
    end
  end


  describe 'page.json' do

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
        expect(File.read(path).strip).to eq(dataset.last_disk_hit[:data].strip)
        expect(dataset.last_ga_hit).to be_present
        expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
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
        expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
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
        expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
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
        expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
      end
    end
  end

  describe 'track.json' do

    context 'with dataset, profile_id, client_id, and event params' do
      it 'records the event' do
        post_data = {
          'dataset' => token, 'profile_id' => profile_id, 'client_id' => client_id, 'path' => '/',
          'category' => 'foo', 'action' => 'testing', 'label' => 'boop!', 'value' => '1'
        }
        post 'meda/track.json', post_data.to_json, :content_type => 'application/json'
        app.settings.connection.join_threads

        expect(last_response).to be_ok
        expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
      end
    end
  end

  describe 'page.gif' do

    request_path = "meda/page.gif?dataset=#{token}&cb=2219723aea1b964fe9d8c23789a4eded757f&hostname=http%3A%2F%2Flocalhost&referrer=&path=%2Fweb%2Fguest%2Fmyblue%3Fp_p_id%3D58%26p_p_lifecycle%3D0%26p_p_state%3Dnormal%26p_p_mode%3Dview%26p_p_col_id%3Dcolumn-1%26p_p_col_count%3D1%26_58_struts_action%3D%252Flogin%252Fcreate_account&title=fepblue.org+-+Welcome&profile_id=471bb8f0593711e48c1e44fb42fffeaa&client_id=d43ce2c8d9daca4ddaca70d3d0957ca96113"
    unknown_path = "meda/page.gif?dataset=#{token}&cb=2219723aea1b964fe9d8c23789a4eded757f&hostname=http%3A%2F%2Flocalhost&referrer=&path=%2Fweb%2Fguest%2Fmyblue%3Fp_p_id%3D58%26p_p_lifecycle%3D0%26p_p_state%3Dnormal%26p_p_mode%3Dview%26p_p_col_id%3Dcolumn-1%26p_p_col_count%3D1%26_58_struts_action%3D%252Flogin%252Fcreate_account_random_ext&title=fepblue.org+-+Welcome&profile_id=471bb8f0593711e48c1e44fb42fffeaa&client_id=d43ce2c8d9daca4ddaca70d3d0957ca96113"
    
    context 'with qs params and path not in white-list' do
      xit 'should return the path excluding query string params' do
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
        expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
      end
    end

    context 'without qs params' do
      it 'should return the path specified' do
        get "meda/page.gif?dataset=#{token}&cb=2219723aea1b964fe9d8c23789a4eded757f&hostname=http%3A%2F%2Flocalhost&referrer=&path=%2Fweb%2Fguest%2Fmyblue&title=fepblue.org+-+Welcome&profile_id=471bb8f0593711e48c1e44fb42fffeaa&client_id=d43ce2c8d9daca4ddaca70d3d0957ca96113"
        #app.settings.connection.join_threads
        expect(dataset.last_hit.props[:path]).to eq('/web/guest/myblue')
        expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
      end
    end

    context 'without a path parameter' do
      it 'should return a bad request' do
        get request_path.sub! 'path', 'paths'
        expect(last_response).to be_bad_request
        expect(last_response.header['Set-Cookie'].include?("__collector_client_id_v1")).to be_eql(true)
      end
    end
  end
end

