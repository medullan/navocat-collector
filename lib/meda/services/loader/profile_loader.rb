require 'uuidtools'
require_relative "../../core/profile_store.rb"

module Meda

  #load the data store with profile data
  class ProfileLoader
	
   	def loadWithDefaultProfile(amount,config) 

      profileStore = Meda::ProfileStore.new(config)

      for i in 0..amount
		profileStore.create_profile({})
	  end

    end


 	def loadWithSomeProfileData(amount,config)

      profileStore = Meda::ProfileStore.new(config)

      for i in 0..amount
      	if( i % 100 == 0 )
      		Meda.logger.info("--Loaded ------- #{i} profiles of #{amount}")
      	end


   #     Meda.logger.info("create profile start")

        time = Benchmark.realtime do
          profileInfo = {}
          profileInfo[:cb] = UUIDTools::UUID.random_create.to_s
          profileInfo[:member_id] = UUIDTools::UUID.random_create.to_s
      
          profile = profileStore.find_or_create_profile(profileInfo)
          profile_id = profile[:id]

          additional_profile_info = {}
          additional_profile_info[:age] = 21
          additional_profile_info[:street] = 'piper'
          profileStore.set_profile(profile_id,additional_profile_info)
        end

        Meda.logger.error("Time elapsed #{time*1000} milliseconds")
      	
    #    Meda.logger.info("create profile end")

    	  end

    end
  end
end

