require File.expand_path '../spec_helper.rb', __FILE__
require File.expand_path '../invalidation_filter.rb', __FILE__ 
# These examples have dependencies, and need to be run in order

describe "Collector Application" do

  test_increment = 1
  token = '3423432423423423423423'
  member_id = '384739284793284293'
  delete_member_id = 'AA84739284793284293'
  dataset = nil
  profile_id = nil
  delete_profile_id = nil
  client_id = 'abcd1234abcd1234'
  connection = nil
  page_params = {}

  before(:all) do
    dataset = Meda::Dataset.new("test_name",{})
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

    options = {}
    options["disk_pool"] = 2
    options["google_analytics_pool"] = 2

	connection = Meda::Collector::Connection.new(options)

	
	page_params[:dataset] = token
  end

  after(:all) do
    Meda.datasets[token] = nil
  end

  describe 'page' do
    it 'returns false with invalidation filter' do
      dataset.hit_filter = InvalidationFilter.new();
      expect(connection.page(page_params)).to be_falsey
    end

    it 'returns true with no filter' do
      dataset.hit_filter = nil
      expect(connection.page(page_params)).to be_truthy
    end
  end

  describe 'track' do
    it 'returns false with invalidation filter' do
      dataset.hit_filter = InvalidationFilter.new();
      expect(connection.track(page_params)).to be_falsey
    end

    it 'returns true with no filter' do
      dataset.hit_filter = nil
      expect(connection.track(page_params)).to be_truthy
    end
  end



end

