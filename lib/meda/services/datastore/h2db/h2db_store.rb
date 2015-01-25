require 'digest'
require_relative '../../connection/h2_profile_data_access_service.rb'


module Meda

  #Implementation of H2 datastore
  class H2DbStore
	
  	attr_reader :db_conn_url

   	def initialize(config)
   	  @db_conn_url = config["config"].h2['db_conn_url']
      @h2db = Meda::H2ProfileDataAccessService.new(@db_conn_url)
    end

    def encode (key, value)
	    k = "cb"
	    cb_hash = "#{Digest::SHA1.hexdigest(k.to_s)}"

        if !key.include?(cb_hash)
	        if key.include?("lookup") 
	        	@h2db.addProfileLookup(key, value)
	        else
        		profile_id = value.delete("id")
        		if(value.length == 0)
       				@h2db.addProfile(profile_id)
       			else
       				@h2db.updateProfile(profile_id, value)
       			end
	        end
	    end
  	end

  	def decode(key)
  		k = "cb"
	    cb_hash = "#{Digest::SHA1.hexdigest(k.to_s)}"

  		if !key.include?(cb_hash)
	    	if key.include?("lookup")
	      		profileLookup = @h2db.lookupProfile(key)
	      		if(profileLookup)
	      			return profileLookup[:profile_id]
	      		else
	      			return false
	      		end
	    	else
	    		profile_id_parts = key.split(":")
	      		return @h2db.getProfile(profile_id_parts[1])
	    	end
	    else
    		return false
      	end
    end

    def key?(key)
      decode(key)
    end

    def delete(key)
      @h2db.removeProfile(key)
   	@h2db.removeProfileLookup(key)
    end

  end
end
