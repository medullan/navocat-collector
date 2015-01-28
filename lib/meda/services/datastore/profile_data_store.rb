require_relative "mapdb/mapdb_store"
require_relative "hashdb/hashdb_store"
require_relative "redisdb/redisdb_store"
require_relative "h2db/h2db_store"
require "benchmark"

module Meda

  #ruby service wrapper for profile database
  class ProfileDataStore
	
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

    def decode(key)
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

    def log_size
      Meda.logger.warn("gettting db size")
      Meda.logger.warn("key size #{@store.key_size}")
      @store.key_size
=begin
      keys = @store.keys
      Meda.logger.warn("key size #{key}")
      
      profile_keys = 0
      lookup_keys = 0
      unknown_keys = 0

      keys.each do |key| 

        if key.start_with?('profile:lookup:')
          lookup_keys = lookup_keys + 1
        elsif key.start_with?('profile')
          profile_keys = profile_keys + 1
        else
          Meda.logger.warn("bad db key #{key}")
          unknown_keys = unknown_keys + 1
        end

      end

      Meda.logger.warn("Total profile keys #{profile_keys}")
      Meda.logger.warn("Total lookup keys #{lookup_keys}")
      Meda.logger.warn("Total unknown keys #{unknown_keys}")
=end
    end
  end
end

