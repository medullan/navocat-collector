require_relative '../../../../lib/meda/services/filter/request_url_filter_service'



describe Meda::RequestURLFilterService do

Meda.configuration.features = {}
Meda.configuration.features["profile_store"] = "hashdb" #mapdb, #h2db
Meda.configuration.features["profile_service"] = "onekey"
config = {}
config["config"] = Meda.configuration
config["name"] = "testdb_#{rand(10000000)}"
config["config"].hash_salt = "a test hash"
Meda.configuration.log_level = 3
Meda.featuresNoCache

	hash = Hash.new()
	hash["rack.input"] = "rack.input"
	hash["REQUEST_URI"] = "www.a.org/meda/identify.gif?dataset=ss&cb=4a262f24ff0c6847ed493d96f8f8c784e83d&member_id=13655045"
	hash["rack.url_scheme"] = "http"
	hash["SCRIPT_NAME"] =""
	hash["PATH_INFO"] = "www.a.org/meda/identify.gif"
	hash["SERVER_PORT"] = "80"
	hash["REQUEST_METHOD"] = "GET"
	hash["QUERY_STRING"] = "dataset=ss&cb=4a262f24ff0c6847ed493d96f8f8c784e83d&member_id=13655045"
	hash['CONTENT_LENGTH'] = "500"
	hash['CONTENT_TYPE']= "application.json"

  describe 'request_url_filter_service' do
    it 'hashes member id from request' do
      	start_string = 'http://www.a.org/meda/identify.gif?dataset=ss&=4a262f24ff0c6847ed493d96f8f8c784e83d&member_id=13655045'
      	expected_end_string = 'http://www.a.org/meda/identify.gif?dataset=ss&cb=4a262f24ff0c6847ed493d96f8f8c784e83d&member_id__hashed=0342094955b65cf608139e4eced98793a6a6494d'
      	
      	hash["QUERY_STRING"] = "dataset=ss&cb=4a262f24ff0c6847ed493d96f8f8c784e83d&member_id=13655045"

      	request = Sinatra::Request.new(hash)
      	request_url_filter_service = Meda::RequestURLFilterService.new(config)
		actual_end_string = request_url_filter_service.filter(request)
		expect(actual_end_string).to eql(expected_end_string)
    end

	  it 'same url when member_id is missing' do

		expected_end_string = 'http://www.a.org/meda/identify.gif?dataset=ss&cb=4a262f24ff0c6847ed493d96f8f8c784e83d&'
		hash["QUERY_STRING"] = "dataset=ss&cb=4a262f24ff0c6847ed493d96f8f8c784e83d&"
		request = Sinatra::Request.new(hash)
		request_url_filter_service = Meda::RequestURLFilterService.new(config)
		actual_end_string = request_url_filter_service.filter(request)
		expect(actual_end_string).to eql(expected_end_string)
	    
	  end

  	it 'should return same url when not identify.gif call' do
      	start_string = 'http://www.a.org/meda/identify2.gif?dataset=ss&cb=4a262f24ff0c6847ed493d96f8f8c784e83d&'
      	expected_end_string = 'http://www.a.org/meda/identify2.gif?dataset=ss&cb=4a262f24ff0c6847ed493d96f8f8c784e83d&'
      	hash["PATH_INFO"] = "www.a.org/meda/identify2.gif"
      	hash["QUERY_STRING"] = "dataset=ss&cb=4a262f24ff0c6847ed493d96f8f8c784e83d&"
      	request = Sinatra::Request.new(hash)
      	request_url_filter_service = Meda::RequestURLFilterService.new(config)
		actual_end_string = request_url_filter_service.filter(request)
		expect(actual_end_string).to eql(expected_end_string)
    end
  end
end
