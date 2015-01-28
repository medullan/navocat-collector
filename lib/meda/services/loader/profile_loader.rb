require 'uuidtools'
require_relative "../../core/profile_store.rb"

module Meda

  #load the data store with profile data
  class ProfileLoader
	
   	def loadWithDefaultProfile(amount, config) 

      profileStore = Meda::ProfileStore.new(config)

      for i in 0..amount
		profileStore.create_profile({})
	  end

    end


 	def loadWithSomeProfileData(amount, config)

      profileStore = Meda::ProfileStore.new(config)
  
	 
      for i in 0..amount
  
    	if( i % 100 == 0 )
    		Meda.logger.info("--Loaded ------- #{i} profiles of #{amount}")
    	end
      	
      profileInfo = {}
    	profileInfo[:cb] = UUIDTools::UUID.random_create.to_s
    	profileInfo[:member_id] = UUIDTools::UUID.random_create.to_s
  
  		profile = profileStore.find_or_create_profile(profileInfo)
  		profile_id = profile[:id]

  		additional_profile_info = {}
  		additional_profile_info[:age] = 21
      additional_profile_info[:gender] = 'male'
      additional_profile_info[:plan_option] = 'some plan'
      additional_profile_info[:member_type] = 'member type'
      additional_profile_info[:health_consumer] = 'some health_consumer'
      additional_profile_info[:segmentation] = 'some segmentation'
      additional_profile_info[:health_segmentation] = 'some health_segmentation'
      additional_profile_info[:consumer_segmentation] = 'some consumer_segmentation'

  		profileStore.set_profile(profile_id,additional_profile_info)

      

	  end

    end
  end
end

