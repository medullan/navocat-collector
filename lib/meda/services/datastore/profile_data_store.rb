require_relative "mapdb/mapdb_store"
require_relative "hashdb/hashdb_store"
require_relative "redisdb/redisdb_store"
require "benchmark"

module Meda

  #ruby service wrapper for profile database
  class ProfileDataStore
	
   	def initialize(config)
#      feature = Meda.features.get_feature_service("profile_store")

#      case feature
#      when "mapdb"
#       @store = Meda::MapDbStore.new(config)
#      when "hashdb"
#        @store = Meda::HashDbStore.new(config)
#      when "redisdb"
        @store = Meda::RedisDbStore.new(config)
#      else
#        raise "feature #{feature} is not implemented"
#      end 
    end

    def encode(key,value)
      Meda.logger.info("starting encode")
      startBenchmark = Time.now.to_f
      @store.encode(key,value)
      endBenchmark = Time.now.to_f
      Meda.logger.info("ending encode in #{endBenchmark-startBenchmark}ms")
    end

    def key?(key)
      Meda.logger.info("starting key check")
      startBenchmark = Time.now.to_f
      result = @store.key?(key)
      endBenchmark = Time.now.to_f
      Meda.logger.info("ending key check  #{endBenchmark-startBenchmark}ms")
      Meda.logger.info("result #{result}")
      return result
    end

    def decode(key)
      Meda.logger.info("starting decode")
      startBenchmark = Time.now.to_f
      result = @store.decode(key)
      endBenchmark = Time.now.to_f
      Meda.logger.info("ending decode #{endBenchmark-startBenchmark}ms")
      return result
    end

    def delete(key)
      Meda.logger.info("starting delete")
      startBenchmark = Time.now.to_f
      @store.delete(key)
      endBenchmark = Time.now.to_f
      Meda.logger.info("ending delete in  #{endBenchmark-startBenchmark}ms")
    end
  end
end

