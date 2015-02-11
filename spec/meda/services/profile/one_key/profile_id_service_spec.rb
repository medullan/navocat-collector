
require_relative '../../../../../lib/meda/services/profile/one_key/profile_id_service.rb'

describe "profile id service" do
	
	Meda.configuration.features = {}
	Meda.configuration.features["profile_store"] = "hashdb" #mapdb, #h2db
	Meda.configuration.features["profile_service"] = "onekey"
	config = {}
	config["config"] = Meda.configuration
	config["name"] = "testdb_#{rand(10000000)}"
	config["config"].hash_salt = "a test hash"
	Meda.configuration.log_level = 3
	Meda.featuresNoCache

	before(:each) do
		@profileIdService = Meda::ProfileIdService.new(config)
	end

	describe 'profile id service' do

		it 'should use hash from config' do
			hash_information = {}
			hash_information[:member_id] = 'test member id'
			expectedHashingResult = 'a90162fc585c42dee9b62b504fd0a86627f0f083'
			result = @profileIdService.mapToHash(hash_information)
			expect(result).to eql(expectedHashingResult)
		end

	end

end

