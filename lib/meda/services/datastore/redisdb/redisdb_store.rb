require 'redis'
require "connection_pool"

module Meda

  #ruby hash implementation profile database
  class RedisDbStore
	
  	REDIS_POOL_DEFAULT = 20 # thread
  	REDIS_TIMEOUT_DEFAULT = 1000 # seconds

   	def initialize(config)
   	  #TODO: replace with @config=config
   	  @config=Meda.configuration
  		#if @redis_pool.nil? && config.redis.present?
  		 #pool_size = config.redis[:pool] || REDIS_POOL_DEFAULT
        #@redis_pool = ConnectionPool.new(size: pool_size, timeout: REDIS_TIMEOUT_DEFAULT) do
          #Redis.new(:host => config.redis[:host], :port => config.redis[:port], :password => config.redis[:password])
        #end
      #end
    end

    def encode(key,value)
      redis do |r|
        #r.set(key, value)
       r.pipelined do |rp|
          if key.include? "lookup"
              rp.sadd(key, value)
          else
              rp.mapped_hmset(key, value)
          end
       end
      
      end
    end

    def key?(key)
      redis do |r|
        return r.exists(key)
      end
    end

    def decode(key)
       returnVal = nil
       values = nil
       redis do |r|
          #return r.get(key)
          if key.include? "lookup"
              values=r.sinter(key)
              if values.length > 0 
                returnVal=values.first
              end
          else
              values=r.hgetall(key)
              if not values.empty?
                returnVal=values
              end
          end
       end
       returnVal
    end

    def delete(key)
      redis do |r|
        r.del(key)
      end
    end
    
    def redis_conn
      if @redis_pool.nil? && @config.redis.present?
        pool_size = @config.redis[:pool] || REDIS_POOL_DEFAULT
        @redis_pool = ConnectionPool.new(size: pool_size, timeout: REDIS_TIMEOUT_DEFAULT) do
          Redis.new(:host => @config.redis[:host], :port => @config.redis[:port], :password => @config.redis[:password])
        end
      end
      @redis_pool
    end

  	def redis(&block)
      #redis_conn=Redis.new(:host => Meda.configuration.redis[:host], :port => Meda.configuration.redis[:port], :password => Meda.configuration.redis[:password])
      #redis_conn.select(1)
      #yield(redis_conn) if block_given?
       redis_conn.with do |conn|
        conn.select(1)
        yield(conn) if block_given?
      end
    end
  end
end

