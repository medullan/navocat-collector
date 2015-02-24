require 'logging'

describe Meda::LoggingMetaDataService do

  describe 'logging meta data service' do
    it 'prefixed a hash' do

    	super_config = {}
    
      	config = Meda::Configuration.new();
      	super_config["config"] = config

      	logging_meta_data_service = Meda::LoggingMetaDataService.new(super_config)	
      	
      	prefix = "query"
		hash =  Hash.new()
		hash["one"] = "test1"
      	hash["two"] = "test2"


		result = logging_meta_data_service.prefix_hash(prefix,hash)

		expect(result["query_one"]).to eql("test1")
		expect(result["query_two"]).to eql("test2")
		expect(result.keys.size).to eql(2)
    end

    it 'remove prefix key from hash' do

    	super_config = {}
      	config = Meda::Configuration.new();
      	super_config["config"] = config

      	logging_meta_data_service = Meda::LoggingMetaDataService.new(super_config)	
      	
      	prefixes = []
      	prefixes.push("query")
      	prefixes.push("cookie")
      	prefixes.push("header")

		hash =  Hash.new()
		hash["query_one"] = "test1"
      	hash["cookie_two"] = "test2"
      	hash["header_two"] = "test3"
      	hash["other_two"] = "test4"

      	key = "two"
		result = logging_meta_data_service.delete_with_prefixes(prefixes,key,hash)

		expect(result["query_one"]).to eql("test1")
		expect(result["cookie_two"]).to be_nil
		expect(result["header_two"]).to be_nil
		expect(result.keys.size).to eql(2)
    end

    it 'setup_meta_logs' do
    	Logging.mdc.clear
    	super_config = {}
      	config = Meda::Configuration.new();
      	super_config["config"] = config
    	
    	logging_meta_data_service = Meda::LoggingMetaDataService.new(super_config)

		hash = Hash.new()
		hash["rack.input"] = "rack.input"
		hash["REQUEST_URI"] = "www.a.org/meda/identify.gif?dataset=ss&cb=4a262f24ff0c6847ed493d96f8f8c784e83d&member_id=13655045"
		hash["rack.url_scheme"] = "http"
		hash["SCRIPT_NAME"] = ""
		hash["PATH_INFO"] = "www.a.org/meda/identify.gif"
		hash["SERVER_PORT"] = "80"
		hash["REQUEST_METHOD"] = "GET"
		hash["QUERY_STRING"] = "dataset=ss&cb=4a262f24ff0c6847ed493d96f8f8c784e83d&member_id=13655045"
		hash['CONTENT_LENGTH'] = "500"
		hash['CONTENT_TYPE']= "application.json"
		hash['REMOTE_ADDR'] = "aa,bb"

    	request = Sinatra::Request.new(hash)
    	headers = {}
    	headers["test_header"] = "two"

    	cookies = {}
    	cookies["test_cookie"] = "one"

    	request_environment = {}
    	request_environment[:user_ip] = "foo"
    	logging_meta_data_service.setup_meta_logs(request,headers,cookies,request_environment)

    	logging_hash =  JSON.parse Logging.mdc["meta_logs"].to_s

    	expect(logging_hash["rack_remote_address"]).to eql("e0c9035898dd52fc65c41454cec9c4d2611bfb37")
    	expect(logging_hash["querystring_dataset"]).to eql("ss")
    	expect(logging_hash["querystring_cb"]).to eql("4a262f24ff0c6847ed493d96f8f8c784e83d")
    	expect(logging_hash["hashed_member_id"]).to eql("441e0a1e280099aacba724248b90ad574c069399")
    	expect(logging_hash["request_url"]).to eql("http://www.a.org/meda/identify.gif?dataset=ss\u0026cb=4a262f24ff0c6847ed493d96f8f8c784e83d\u0026member_id__hashed=441e0a1e280099aacba724248b90ad574c069399")
    	expect(logging_hash["request_url_path"]).to eql("www.a.org/meda/identify.gif")
    	expect(logging_hash["request_ip"]).to eql("0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33")
    	expect(logging_hash["hashed_member_id"]).to eql("441e0a1e280099aacba724248b90ad574c069399")
    	expect(logging_hash["header_test_header"]).to eql("two")
    	expect(logging_hash["cookie_test_cookie"]).to eql("one")
    end

    it 'adds to mdc with empty logging' do
    	Logging.mdc.clear
    	super_config = {}
      	config = Meda::Configuration.new();
      	super_config["config"] = config
    	
    	logging_meta_data_service = Meda::LoggingMetaDataService.new(super_config)

    	logging_meta_data_service.add_to_mdc("test_key","test_value")
    	logging_hash =  JSON.parse Logging.mdc["meta_logs"].to_s

    	expect(logging_hash["test_key"]).to eql("test_value")
    	expect(logging_hash.keys.size).to eql(1)
    end

    it 'adds to mdc with existing mdc' do

		hash = Hash.new()
		hash["rack.input"] = "rack.input"

    	Logging.mdc.clear
    	Logging.mdc["meta_logs"] = hash.to_json

    	super_config = {}
      	config = Meda::Configuration.new();
      	super_config["config"] = config
    	
    	logging_meta_data_service = Meda::LoggingMetaDataService.new(super_config)

    	logging_meta_data_service.add_to_mdc("test_key","test_value")
    	logging_hash =  JSON.parse Logging.mdc["meta_logs"].to_s

    	expect(logging_hash["test_key"]).to eql("test_value")
    	expect(logging_hash.keys.size).to eql(2)
    end

  end


end
