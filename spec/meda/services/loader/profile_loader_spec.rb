require_relative '../../../../lib/meda/services/loader/profile_loader.rb'



describe "loader" do
	describe 'load profilestore' do
		Meda.configuration.features = {}
		Meda.configuration.features["profile_store"] = "hashdb" #mapdb, #h2db
		Meda.configuration.features["profile_service"] = "lookup"
		store_config = {}
		store_config["config"] = Meda.configuration
		store_config["name"] = "testdb_#{rand(10000000)}"

		Meda.featuresNoCache
		
		@profileLoader = Meda::ProfileLoader.new()

		#loadWithSomeProfileData
		@profileLoader.loadWithDefaultProfile(20,store_config)
    end
end

