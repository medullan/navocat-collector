require_relative "../../core/profile_store.rb"

module Meda

  #load the data store with profile data
  class ProfileLoader
	
   	def loadWithDefaultProfile(count,config) 

      profileStore = Meda::ProfileStore.new(config)

      for i in 0..count
		profileStore.create_profile({})
	  end

    end


 	def loadWithSomeProfileData(count,config)

      profileStore = Meda::ProfileStore.new(config)
      profileInfo = {}
      profileInfo["gender"] = "male"
      profileInfo["age"] = 21
	  profileInfo["street"] = "piper"
		

      for i in 0..count
		profileStore.create_profile(profileInfo)
	  end

    end
  end
end

