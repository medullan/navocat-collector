require 'uuidtools'
require 'digest'
require 'logger'

require_relative '../../datastore/profile_data_store.rb'
require_relative '../../profile/one_key/profile_id_service.rb'

module Meda

  # Implements persistence of profile into the profile data store limit to one key per profile
  class ProfileWithOneKeyService

    attr_reader :profile_db,:profile_id_service

    def initialize(config)
      @profile_db = Meda::ProfileDataStore.new(config)
      @profile_id_service = Meda::ProfileIdService.new(config)
    end

    # Create a new profile with the identifying info in the given hash
    def create_profile(info)
      logger.debug("profile info -> #{info.to_s}")

      profileIdHashInformation = {}
      profileIdHashInformation[:member_id] = info[:member_id]
      profile_id = @profile_id_service.mapToHash(profileIdHashInformation)

      @profile_db.encode(profile_id,{'id' => profile_id})

      ActiveSupport::HashWithIndifferentAccess.new({'id' => profile_id})
    end

    # Add additional identifying info in the given hash to an existing profile
    def alias_profile(profile_id, info)
      raise "alias/additional lookups are deprecated"
    end

    # Find or create a profile for the identifying info in the given hash
    def find_or_create_profile(info)

      profile_id = info[:profile_id]
      if(info[:profile_id])
        profile = get_profile_by_id(profile_id)
      elsif(info[:member_id])   
        profileIdHashInformation = {}
        profileIdHashInformation[:member_id] = info[:member_id]
        profile_id = @profile_id_service.mapToHash(profileIdHashInformation)
        profile = get_profile_by_id(profile_id)
      end

      if(profile == false)
        profile = create_profile(info)
      end

      profile
    end

    # Return a hash with the profile info for the given profile_id
    def get_profile_by_id(profile_id)

      if @profile_db.key?(profile_id)    
        ActiveSupport::HashWithIndifferentAccess.new(@profile_db.decode(profile_id))
      else
        logger.warn("get_profile_by_id ==> No profile found with key #{profile_id}")
        false # no profile
      end
    end

    # Set additional attributes on a profile from the given profile_info hash
    def set_profile(profile_id, profile_info)
      if @profile_db.key?(profile_id)
        existing_profile = @profile_db.decode(profile_id)
        @profile_db.encode(profile_id, existing_profile.merge(profile_info))
        true
      else
        logger.error("INVALID POINT -- set_profile ==> No profile found with key #{profile_id}")
        false # no profile
      end
    end

    # delete profile given profile if
    def delete_profile(profile_id)
      if @profile_db.key?(profile_id)
        @profile_db.delete(profile_id)
        true
      else
        logger.error("INVALID POINT -- delete_profile ==> No profile found with key #{profile_id}")
        false # no profile
      end
    end

    # Uses one criteria at a time from the given hash, in order, until a match is found
    def lookup_profile(info)
      raise "lookup_profile is deprecated"
    end

    # TreeMap key for hashed profile lookup key
    def key_hashed_profile_lookup(k,v)
      raise "lookup_profile is deprecated"
    end

    # TreeMap key for profile data
    def profile_key(id)
      raise "lookup_profile is deprecated"
    end

    def logger
      @logger ||= Meda.logger || Logger.new(STDOUT)
    end

  end
end
