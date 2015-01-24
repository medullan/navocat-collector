require 'redis'
require "connection_pool"

module Meda

  #ruby hash implementation profile database
  class RedisDbStore
	
  	REDIS_POOL_DEFAULT = 1 # thread
  	REDIS_TIMEOUT_DEFAULT = 5 # seconds

   	def initialize(config)
  		if @redis_pool.nil? && config.redis.present?
  		  pool_size = config.redis[:pool] || REDIS_POOL_DEFAULT
  		  @redis_pool = ConnectionPool.new(size: pool_size, timeout: REDIS_TIMEOUT_DEFAULT) do
  		    Redis.new(:host => config.redis[:host], :port => config.redis[:port], :password => config.redis[:password])
  		  end
		end
		@redis_pool
    end

    def encode(key,value)
      redis do |r|
        r.set(key, value)
      end
    end

    def key?(key)
      exists = false
      redis do |r|
        exists = r.exists(key)
      end
      exists
    end

    def decode(key)
      redis do |r|
        return r.get(key)
      end
     
    end

    def delete(key)
      redis do |r|
        r.del(key)
      end
    end


  	def redis(&block)
      #redis_conn=Redis.new(:host => Meda.configuration.redis[:host], :port => Meda.configuration.redis[:port], :password => Meda.configuration.redis[:password])
      #redis_conn.select(1)
      #yield(redis_conn) if block_given?
       Meda.redis.with do |conn|
        conn.select(1)
        yield(conn) if block_given?
      end
    end
  end
end

