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

  describe 'index' do
    it 'says hello world' do
      get '/'
      last_response.should be_ok
    end
  end

  describe 'identify.json' do

    it 'identifies a new user' do
      post_data = {'dataset' => token, 'member_id' => member_id}
      post 'identify.json', post_data.to_json, :content_type => 'application/json'
      expect(last_response).to be_ok
      body = JSON.parse(last_response.body)
      expect(body['profile_id']).to be_present
      profile_id = body['profile_id']
    end

  end

  describe 'profile.json' do

    it 'posts profile info' do
      post_data = {'dataset' => token, 'profile_id' => profile_id, 'state' => 'Maine', 'weight' => '200'}
      post 'profile.json', post_data.to_json, :content_type => 'application/json'
      expect(last_response).to be_ok
    end

  end

  describe 'profile.json' do

    it 'posts profile with bad profile_id' do
      post_data = {'dataset' => token, 'profile_id' => 'some-bad-profile-id', 'state' => 'Maine', 'weight' => '200'}
      post 'profile.json', post_data.to_json, :content_type => 'application/json'
      expect(last_response).to be_bad_request
    end

  end

  describe 'getprofile.json' do

    it 'get profile info' do
      post_data = {'dataset' => token, 'profile_id' => profile_id}
      post 'getprofile.json', post_data.to_json, :content_type => 'application/json' 
      body = JSON.parse(last_response.body)
      expect(body['state']).to be_present
      state = body['state']
      expect(state).to eq('Maine')
    end

  end


  describe 'getprofile.json' do

    it 'get profile info with bad profile_id' do
      post_data = {'dataset' => token, 'profile_id' => 'some-bad-profile-id'}
      post 'getprofile.json', post_data.to_json, :content_type => 'application/json' 
      expect(last_response).to be_bad_request
    end

  end

  describe 'page.json' do

    context 'with missing client_id' do
      it 'responds with bad request' do
        post_data = {
          'dataset' => token, 'profile_id' => profile_id,
          'title' => 'foo', 'hostname' => 'http://www.example.com'
        }
        post 'page.json', post_data.to_json, :content_type => 'application/json'
        app.settings.connection.join_threads

        expect(last_response).to be_bad_request
      end
    end

    context 'with dataset, profile_id, client_id, and page params' do
      it 'records the pageview' do
        post_data = {
          'dataset' => token, 'profile_id' => profile_id, 'client_id' => client_id,
          'title' => 'foo', 'hostname' => 'http://www.example.com'
        }
        post 'page.json', post_data.to_json, :content_type => 'application/json'
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
          'title' => 'foo', 'hostname' => 'http://www.example.com', 'user_ip' => '123.123.123.123'
        }
        post 'page.json', post_data.to_json, :content_type => 'application/json'
        expect(dataset.last_hit.props[:user_ip]).to eq('123.123.123.0')
      end
    end

    context 'with REMOTE_ADDR header' do
      it 'records a pageview with that IP de-identified' do
        post_data = {
          'dataset' => token, 'profile_id' => profile_id, 'client_id' => client_id,
          'title' => 'foo', 'hostname' => 'http://www.example.com'
        }
        post 'page.json', post_data.to_json, { :content_type => 'application/json',
          'REMOTE_ADDR' => '123.123.123.123' }
        expect(dataset.last_hit.props[:user_ip]).to eq('123.123.123.0')
      end
    end

    context 'with X_FORWARDED_FOR header set by a proxy server' do
      it 'records a pageview with that IP de-identified' do
        post_data = {
          'dataset' => token, 'profile_id' => profile_id, 'client_id' => client_id,
          'title' => 'foo', 'hostname' => 'http://www.example.com'
        }
        post 'page.json', post_data.to_json, { :content_type => 'application/json',
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
          'category' => 'foo', 'action' => 'testing', 'label' => 'boop!', 'value' => '1'
        }
        post 'track.json', post_data.to_json, :content_type => 'application/json'
        app.settings.connection.join_threads

        expect(last_response).to be_bad_request
      end
    end

    context 'with dataset, profile_id, client_id, and event params' do
      it 'records the event' do
        post_data = {
          'dataset' => token, 'profile_id' => profile_id, 'client_id' => client_id,
          'category' => 'foo', 'action' => 'testing', 'label' => 'boop!', 'value' => '1'
        }
        post 'track.json', post_data.to_json, :content_type => 'application/json'
        app.settings.connection.join_threads

        expect(last_response).to be_ok
      end
    end
  end
end

