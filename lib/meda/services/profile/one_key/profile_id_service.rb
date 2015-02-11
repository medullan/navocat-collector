require 'uuidtools'
require 'digest'
require 'logger'

require_relative '../../datastore/profile_data_store.rb'

module Meda

  # Implements hashing with salt for profile ids
  class ProfileIdService
 
    def initialize(config)
      @hash_salt = config["config"].hash_salt
    end

    def mapToHash(hash_information)  	
    	
    	member_id = hash_information[:member_id]
    	hashing_data = member_id.to_s + @hash_salt
    	Digest::SHA1.hexdigest(hashing_data)
    end

  end
end
