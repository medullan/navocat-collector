require 'redis'
require 'json'
require "connection_pool"

module Meda

  #ruby hash implementation profile database
  class RedisDbStore
	
  	REDIS_POOL_DEFAULT = 10 # thread
  	REDIS_TIMEOUT_DEFAULT = 15 # seconds

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
        pool_size = @config.redis['pool'] || REDIS_POOL_DEFAULT
        time_out = @config.redis['time_out'] || REDIS_TIMEOUT_DEFAULT
        redis_host = ENV['REDIS_HOST'] || @config.redis['host']
        redis_port = ENV['REDIS_PORT'] || @config.redis['port']
        redis_pwd = ENV['REDIS_PWD'] || @config.redis['password']
        @redis_pool = ConnectionPool.new(size: pool_size, timeout: time_out) do
          Redis.new(:host => redis_host, :port => redis_port, :password => redis_pwd)
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


    #Collection APIs
    def scan_keys(pattern, cursor=0, count=1000)
      redis do |r|
        keys = []
        if !pattern.nil?
          cursor = cursor || 0
          count = count || 100
          count = (count + 10)
          keys = r.scan(cursor, :match => pattern, :count => count )[1]
        end
        return keys
      end
    end

    def multi_decode(keys)
      redis do |r|
        result = []
        if !keys.nil? && !keys.empty?
          result = r.mget(keys)
        end
        return result
      end
    end

    def set(key,value)
      redis do |r|
        r.set(key, value)
      end
    end

    def get(key)
      returnVal = nil
      redis do |r|
       result = r.get(key)
        if !result.nil? && !result.empty?
          return JSON.parse(result)
        end
       returnVal
      end
    end

    def increment(key)
      redis do |r|
        r.incr(key)
      end
    end

  end
end

