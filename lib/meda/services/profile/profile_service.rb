require_relative 'look_up/profile_with_look_up_service.rb'
require_relative 'one_key/profile_with_one_key_service.rb'

module Meda

  #abstracts profile service implementaton
  class ProfileService
	
   	def initialize(config)
      feature = Meda.features.get_feature_service("profile_service")
      case feature
      when "lookup"
        @service = Meda::ProfileWithLookUpService.new(config)
      when "onekey"
        @service = Meda::ProfileWithOneKeyService.new(config)
      else
        raise "feature #{feature} is not implemented"
      end 
    end

    def create_profile(info)
      @service.create_profile(info)
    end

    def find_or_create_profile(info)
      @service.find_or_create_profile(info)
    end

    def set_profile(profile_id, profile_info)
      @service.set_profile(profile_id, profile_info)
    end

    def get_profile_by_id(profile_id)
      @service.get_profile_by_id(profile_id)
    end

    def delete_profile(profile_id)
      @service.delete_profile(profile_id)
    end

    def alias_profile(profile_id, info)
      @service.alias_profile(profile_id, info)
    end

    def lookup_profile(info)
      @service.lookup_profile(info)
    end

    def key_hashed_profile_lookup(k,v)
       @service.key_hashed_profile_lookup(k,v)
    end

    def profile_key(id)
      @service.profile_key(id)
    end

  end
end

