require 'uuidtools'
require 'digest'
require 'logger'

require_relative '../../datastore/profile_data_store.rb'

module Meda

  # Implements persistence of profile into the profile data store limit to one key per profile
  class ProfileIdService

	HASH_SALT = 'df0eeebcb59104b6d2a3506d39'
    
    def initialize(config)
      
    end

    def mapToHash(hash_information)  	
    	
    	member_id = hash_information[:member_id]
    	hashing_data = member_id.to_s + HASH_SALT
    	Digest::SHA1.hexdigest(hashing_data)
    end

  end
end
