

require_relative '../../../../../lib/meda/services/profile/profile_service.rb'
require_relative '../../../../../lib/meda/services/profile/one_key/profile_with_one_key_service.rb'
require_relative '../../../../../lib/meda/services/profile/one_key/profile_id_service.rb'

describe "profile service" do
	
	Meda.configuration.features = {}
	Meda.configuration.features["profile_store"] = "hashdb" #mapdb, #h2db
	Meda.configuration.features["profile_service"] = "onekey"
	store_config = {}
	store_config["config"] = Meda.configuration
	store_config["name"] = "testdb_#{rand(10000000)}"
	Meda.configuration.log_level = 3
	Meda.featuresNoCache

	before(:each) do
		@profileService = Meda::ProfileWithOneKeyService.new(Meda.configuration)
	end

	describe 'one key profile service' do

		it 'find or create one profile' do
			member_info_1 = {}
			member_info_1[:member_id] = 'test member id'

			result = @profileService.find_or_create_profile(member_info_1)
			expect(@profileService.profile_db.size).to eq(1)
		end

		it 'find or create two profiles' do
			member_info_1 = {}
			member_info_1[:member_id] = 'test member id'

			@profileService.find_or_create_profile(member_info_1)
	
			member_info_2 = {}
			member_info_2[:member_id] = 'test member id 2'

			@profileService.find_or_create_profile(member_info_2)
			expect(@profileService.profile_db.size).to eq(2)
		end

		it 'set_profile with one additional attribute' do
			member_info_1 = {}
			member_info_1[:member_id] = 'test member id'

			result = @profileService.find_or_create_profile(member_info_1)
			expect(@profileService.profile_db.size).to eq(1)
		end

		it 'set_profile with additional attributes' do
			member_info_1 = {}
			member_info_1[:member_id] = 'test member id'

			additional_info = {}
			additional_info[:gender] = "male"
			additional_info[:age] = "21"

			profile = @profileService.find_or_create_profile(member_info_1)
			set_profile_result = @profileService.set_profile(profile[:id],additional_info)
			expect(set_profile_result).to be_truthy

			profile_with_additonal_info = @profileService.get_profile_by_id(profile[:id])
			expect(profile_with_additonal_info[:gender]).to eq("male")
			expect(profile_with_additonal_info[:age]).to eq("21")
		end

		it 'delete_profile' do
			member_info_1 = {}
			member_info_1[:member_id] = 'test member id'

			profile = @profileService.find_or_create_profile(member_info_1)
			expect(@profileService.profile_db.size).to eq(1)
			@profileService.delete_profile(profile[:id])
			expect(@profileService.profile_db.size).to eq(0)

		end

	end

end

