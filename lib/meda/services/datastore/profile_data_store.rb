require_relative "mapdb/mapdb_store"
require_relative "hashdb/hashdb_store"
require_relative "redisdb/redisdb_store"

module Meda

  #ruby service wrapper for profile database
  class ProfileDataStore
	
   	def initialize(config)
#      feature = Meda.features.get_feature_service("profile_store")

#      case feature
#      when "mapdb"
        @store = Meda::MapDbStore.new(config)
#      when "hashdb"
#        @store = Meda::HashDbStore.new(config)
#      when "redisdb"
#        @store = Meda::RedisDbStore.new(config)
#      else
#        raise "feature #{feature} is not implemented"
#      end 
    end

    def encode(key,value)
      Meda.logger.info("starting encode")
      @store.encode(key,value)
      Meda.logger.info("ending encode")
    end

    def key?(key)
      Meda.logger.info("starting key check")
      result = @store.key?(key)
      Meda.logger.info("ending key check")
      Meda.logger.info("result #{result}")
      return result
    end

    def decode(key)
      Meda.logger.info("starting decode")
      result = @store.decode(key)
      Meda.logger.info("ending decode")
      Meda.logger.info("result #{result}")
      return result
    end

    def delete(key)
      Meda.logger.info("starting delete")
      @store.delete(key)
      Meda.logger.info("edning delete")
    end
  end
end

