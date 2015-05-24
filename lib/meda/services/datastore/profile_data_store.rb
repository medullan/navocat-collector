require_relative "mapdb/mapdb_store"
require_relative "hashdb/hashdb_store"
require_relative "redisdb/redisdb_store"
require_relative "h2db/h2db_store"
require "benchmark"

module Meda

  #ruby service wrapper for profile database
  class ProfileDataStore
	  attr_reader :store
   	def initialize(config)
      feature = Meda.features.get_feature_service("profile_store")
      case feature
      when "mapdb"
        @store = Meda::MapDbStore.new(config)
      when "hashdb"
        @store = Meda::HashDbStore.new(config)
      when "redisdb"
        @store = Meda::RedisDbStore.new(config)
      when "h2"
        @store = Meda::H2DbStore.new(config)
      else
        raise "feature #{feature} is not implemented"
      end 
    end

    def encode_collection(list, key, value)
      @store.encode_collection(list, key, value)
    end

    def decode_collection(list)
      @store.decode_collection(list)
    end
    def decode_collection_filter_by_key(list, key)
      @store.decode_collection_filter_by_key(list, key)
    end
    def delete_key_within_collection(list, key)
      @store.delete_key_within_collection(list, key)
    end
    def key_in_collection?(list, key)
      @store.key_in_collection?(list, key)
    end

    def encode(key,value)
      Meda.logger.debug("starting encode")
      startBenchmark = Time.now.to_f
      @store.encode(key,value)
      endBenchmark = Time.now.to_f
      Meda.logger.debug("ending encode in #{endBenchmark-startBenchmark}ms")
    end

    def key?(key)
      Meda.logger.debug("starting key check")
      startBenchmark = Time.now.to_f
      result = @store.key?(key)
      endBenchmark = Time.now.to_f
      Meda.logger.debug("ending key check  #{endBenchmark-startBenchmark}ms")
      Meda.logger.debug("result #{result}")
      return result
    end

    def decode(key, list=false)
      Meda.logger.debug("starting decode")
      startBenchmark = Time.now.to_f
      result = @store.decode(key)
      endBenchmark = Time.now.to_f
      Meda.logger.debug("ending decode #{endBenchmark-startBenchmark}ms")
      return result
    end

    #better ruby benchmark
    def delete(key)
      Meda.logger.debug("starting delete")
      startBenchmark = Time.now.to_f
      @store.delete(key)
      endBenchmark = Time.now.to_f
      Meda.logger.debug("ending delete in  #{endBenchmark-startBenchmark}ms")
    end

    def size
       @store.key_size
    end

    def log_size
      Meda.logger.warn("gettting db size")
      Meda.logger.warn("key size #{@store.key_size}")
      @store.key_size
    end



  end
end

