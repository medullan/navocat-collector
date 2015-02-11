require 'uuidtools'
require_relative "../../services/profile/profile_service.rb"

module Meda

  #load the data store with profile data
  class ProfileLoader
	
   	def loadWithDefaultProfile(amount, config) 

      profileService = Meda::ProfileService.new(config)

      for i in 0..amount
  	 	   profileService.create_profile({})
  	  end

    end


 	def loadWithSomeProfileData(amount, config)

      profileService = Meda::ProfileService.new(config)

      for i in 0..amount

      	if( i % 100 == 0 )
      		Meda.logger.info("--Loaded ------- #{i} profiles of #{amount}")
          sleep(1)
      	end
        	
        profileInfo = {}
      	profileInfo[:cb] = UUIDTools::UUID.random_create.to_s
      	profileInfo[:member_id] = UUIDTools::UUID.random_create.to_s
    
    		profile = profileService.find_or_create_profile(profileInfo)
    		profile_id = profile[:id]

    		additional_profile_info = {}
    		additional_profile_info[:age] = 21
        additional_profile_info[:gender] = 'male'
        additional_profile_info[:plan_option] = (0...200).map { ('a'..'z').to_a[rand(26)] }.join
        additional_profile_info[:member_type] = (0...200).map { ('a'..'z').to_a[rand(26)] }.join
        additional_profile_info[:health_consumer] = (0...200).map { ('a'..'z').to_a[rand(26)] }.join
        additional_profile_info[:segmentation] = (0...200).map { ('a'..'z').to_a[rand(26)] }.join
        additional_profile_info[:health_segmentation] = (0...200).map { ('a'..'z').to_a[rand(26)] }.join
        additional_profile_info[:consumer_segmentation] = (0...200).map { ('a'..'z').to_a[rand(26)] }.join
        additional_profile_info[:some_attrib_one] = (0...200).map { ('a'..'z').to_a[rand(26)] }.join
        additional_profile_info[:some_attrib_two] = (0...200).map { ('a'..'z').to_a[rand(26)] }.join
        additional_profile_info[:some_attrib_three] = (0...200).map { ('a'..'z').to_a[rand(26)] }.join

    		profileService.set_profile(profile_id,additional_profile_info)

      end
    end
  end
end

