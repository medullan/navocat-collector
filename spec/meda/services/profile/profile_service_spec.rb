require_relative '../../../../lib/meda/services/profile/profile_service.rb'

describe "profile service" do
	
	Meda.configuration.features = {}
	Meda.configuration.features["profile_store"] = "hashdb" #mapdb, #h2db
	Meda.configuration.features["profile_service"] = "lookup"
	store_config = {}
	store_config["config"] = Meda.configuration
	store_config["name"] = "testdb_#{rand(10000000)}"

	Meda.featuresNoCache

	
	describe 'facaded method exists' do
		it 'create_profile' do
			@profileService = Meda::ProfileService.new(Meda.configuration)

			info = {}
			profile_id = @profileService.create_profile(info)
			expect(profile_id).not_to be_nil 
		end

		it 'find_or_create_profile' do
			@profileService = Meda::ProfileService.new(Meda.configuration)

			info = {}
			profile = @profileService.find_or_create_profile(info)
			expect(profile).not_to be_nil 
			
		end

		it 'set_profile' do
			@profileService = Meda::ProfileService.new(Meda.configuration)

			info = {}
			profile = @profileService.set_profile('id',info)
			expect(profile).not_to be_nil 
		end

		it 'get_profile_by_id' do
			@profileService = Meda::ProfileService.new(Meda.configuration)

			profile = @profileService.get_profile_by_id('id')
			expect(profile).not_to be_nil 
		end

		it 'delete_profile' do
			@profileService = Meda::ProfileService.new(Meda.configuration)

			profile = @profileService.delete_profile('id')
			expect(profile).to be_falsey 
		end

		it 'alias_profile' do
			@profileService = Meda::ProfileService.new(Meda.configuration)

			info = {}
			profile = @profileService.alias_profile('id',info)
			expect(profile).not_to be_nil			
			
		end

		it 'lookup_profile' do
			@profileService = Meda::ProfileService.new(Meda.configuration)

			info = {}
			profile = @profileService.lookup_profile(info)
			expect(profile).not_to be_nil
			
		end

		it 'key_hashed_profile_lookup' do
			@profileService = Meda::ProfileService.new(Meda.configuration)
			profile = @profileService.key_hashed_profile_lookup('a','b')
			expect(profile).not_to be_nil
		end

		it 'profile_key' do
			@profileService = Meda::ProfileService.new(Meda.configuration)

			info = {}
			profile = @profileService.profile_key(info)
			expect(profile).not_to be_nil
			
		end
	end

end

