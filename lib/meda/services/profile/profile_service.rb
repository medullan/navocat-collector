
module Meda

  class ProfileService
	
	  def features
      @features ||= Meda.features
    end

    def logger
      @logger ||= Meda.logger
    end

   	def initialize()
      @hash = Hash.new();
    end

    # Set additional attributes on a profile from the given profile_info hash
    def set_profile(profile_id, profile_info)
      info = get_profile_by_id(profile_id)
      if info.nil?
        logger.error("profile id #{profile_id} should exist")
        return false
      else
        merged_profile = info.merge(profile_info)
        @hash[profile_id] = merged_profile
        return true
      end

    end
    
    # Return a hash with the profile info for the given profile_id
    def get_profile_by_id(profile_id)
      result = @hash[profile_id]
      if result.nil?
        logger.warn("no profile with #{profile_id} exists")
        return nil
      end

      result
    end

    def delete_profile(profile_id)
      @hash.delete(profile_id)
    end

    # Find or create a profile for the identifying info in the given hash
    def find_or_create_profile(info)
      logger.info("calling get get_profile_by_id")
      profile = get_profile_by_id(info)
      if profile.nil?
        logger.info("profile is nil")
        return create_profile(info)
      end
      logger.info("found profile")
      return profile
    end

    # Create a new profile with the identifying info in the given hash
    def create_profile(info)
      profile_id =  UUIDTools::UUID.random_create.hexdigest.to_s
      info[:profile_id] = profile_id
      info[:id] = profile_id
      @hash[profile_id] = info
      logger.info("returning new profile #{info}")
      return info
    end
  end
end



