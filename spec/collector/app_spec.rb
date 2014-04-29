require File.expand_path '../spec_helper.rb', __FILE__

# These examples have dependencies, and need to be run in order

describe "Collector Application" do

  token = '3423432423423423423423'
  member_id = '384739284793284293'
  dataset = nil
  profile_id = nil

  before(:all) do
    dataset = Meda::Dataset.new('test', 1)
    dataset.token = token
    dataset.google_analytics = {'record' => false}
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
      post_data = {'dataset' => token, 'profile_id' => profile_id, 'member_id' => member_id}
      post 'profile.json', post_data.to_json, :content_type => 'application/json'
      expect(last_response).to be_ok
    end

  end

  describe 'page.json' do

    it 'posts page info' do
      post_data = {
        'dataset' => token, 'profile_id' => profile_id,
        'title' => 'foo', 'hostname' => 'http://www.example.com'
      }
      post 'page.json', post_data.to_json, :content_type => 'application/json'
      expect(last_response).to be_ok
    end

  end

  describe 'track.json' do

    it 'posts event info' do
      post_data = {
        'dataset' => token, 'profile_id' => profile_id,
        'category' => 'foo', 'action' => 'testing', 'label' => 'boop!', 'value' => '1'
      }
      post 'track.json', post_data.to_json, :content_type => 'application/json'
      expect(last_response).to be_ok
    end

  end
end

