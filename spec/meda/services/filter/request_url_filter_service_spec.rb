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

  describe 'request_url_filter_service' do
    it 'hashes member id from request' do
      	start_string = 'http://www.a.org/meda/identify.gif?dataset=ss\u0026cb=4a262f24ff0c6847ed493d96f8f8c784e83d\u0026member_id=13655045'
      	expected_end_string = 'http://www.a.org/meda/identify.gif?dataset=ss\\u0026cb=4a262f24ff0c6847ed493d96f8f8c784e83d\\u0026member_id__hashed=426078600bb3140371cd40349e1f2b9037b3ac83'

      	request_url_filter_service = Meda::RequestURLFilterService.new(config)
		actual_end_string = request_url_filter_service.filter(start_string)
		expect(actual_end_string).to eql(expected_end_string)
    end
  end


end
