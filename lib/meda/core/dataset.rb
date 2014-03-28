require 'redis'
require 'ostruct'
require 'uuidtools'
require 'digest'
require 'csv'
require 'securerandom'

module Meda
  class Dataset

    attr_reader :name, :rdb
    # attr_accessor :ga_account

    def initialize(name, rdb=1)
      @name = name
      @rdb = rdb
    end

    def identify_user(info)
      user = find_or_create_user(info)
      return OpenStruct.new({
        :user_id => user['user_id'],
        :profile_id => user['profile_id']
      })
    end

    def add_event(event_props)
      event_props[:time] ||= DateTime.now.to_s
      event_props[:category] ||= 'none'
      event = Meda::Event.new(event_props)
      add_hit(event)
    end

    def add_pageview(page_props)
      page_props[:time] ||= DateTime.now.to_s
      pageview = Meda::Pageview.new(page_props)
      add_hit(pageview)
    end

    def add_hit(hit)
      hit.id = UUIDTools::UUID.timestamp_create.hexdigest
      if hit.profile_id
        profile = get_profile_by_id(hit.profile_id)
        hit.profile_props = profile.hashed_attributes
      else
        # Hit has no profile
        # Leave it anonymous-ish for now. Figure out what to do later.
      end

      hit.validate! # blows up if missing attrs
      enqueue_hit_to_disk(hit)
      enqueue_hit_to_ga(hit)
    end

    def enqueue_hit_to_disk(hit)
      hit_key = "new_#{hit.hit_type_plural}"
      range_key = "new_#{hit.hit_type_plural}:#{hit.hour}"

      redis.pipelined do
        redis.zadd(hit_key, hit.hour_value.to_s, range_key)
        redis.zadd(range_key, hit.time_value.to_s, hit.to_json)
      end
    end

    def enqueue_hit_to_ga(hit)
      hit_key = "ga_new_#{hit.hit_type_plural}"
      redis.rpush(hit_key, hit.to_ga_json)
    end

    def set_profile(profile_id, profile_info)
      redis.mapped_hmset("profile:#{profile_id}", profile_info)
    end

    def ga_account
      "UA-47758842-2" # temporary, of course
    end

    # UNTESTED
    # add dataset to redis

    def self.create(name, rdb, ga=nil)
      id = UUIDTools::UUID.timestamp_create.hexdigest
      token = SecureRandom.hex(16)
      redis_meta.sadd("datasets", id)
      redis_meta.set("dataset:lookup:name:#{name}", id)
      redis_meta.set("dataset:lookup:token:#{token}", id)
      redis_meta.mapped_hmset("dataset:#{id}", {
        'id' => id, 'name' => name, 'token' => token, 'rdb' => rdb
      })
      Meda::Dataset.new(name, rdb)
    end

    # UNTESTED
    # clear dataset from redis

    def self.destroy(name)
      id = redis_meta.get("dataset:lookup:name:#{name}")
      rdb = redis_meta.hget("dataset:#{id}", 'rdb')
      token = redis_meta.hget("dataset:#{id}", 'token')
      redis_meta.del("dataset:lookup:name:#{name}")
      redis_meta.del("dataset:lookup:token:#{token}")
      redis_meta.del("dataset:#{id}")
      dataset_rdb = Redis.new(Meda.configuration.redis.merge(:db => rdb))
      dataset_rdb.flushall
      true
    end

    # UNTESTED
    # return all datasets in the redis

    def self.all
      ids = redis_meta.smembers('datasets')
      ids.map do |id|
        name = redis_meta.hget("dataset:#{id}", 'name')
        rdb = redis_meta.hget("dataset:#{id}", 'rdb')
        Meda::Dataset.new(name, rdb)
      end
    end

    protected

    def find_or_create_user(info)
      user_id = lookup_user(info)
      if user_id
        get_user_by_id(user_id)
      else
        create_user(info)
      end
    end

    def get_user_by_id(user_id)
      redis.hgetall("user:#{user_id}")
    end

    def get_profile_by_id(profile_id)
      profile_info = redis.hgetall("profile:#{profile_id}")
      Meda::Profile.new(self, profile_info)
    end

    # Uses one criteria at a time, in order, until a unique match is found

    def lookup_user(info)
      lookup_keys = info.map{|k,v| "user:lookup:#{k}:#{v}"}
      user_id = nil
      test_keys = []
      while (user_id.nil? && lookup_keys.length > 0) do
        test_keys << lookup_keys.shift
        user_ids = redis.sinter(test_keys)
        user_id = user_ids.first if user_ids.length == 1
      end
      user_id
    end

    def create_user(info)
      user_info = {
        'user_id' => UUIDTools::UUID.timestamp_create.hexdigest,
        'profile_id' => UUIDTools::UUID.timestamp_create.hexdigest
      }.merge(info)

      redis.pipelined do
        redis.mapped_hmset("user:#{user_info['user_id']}", user_info)
        user_info.each_pair{|k, v| redis.sadd("user:lookup:#{k}:#{v}", user_info['user_id'])}
      end
      return user_info
    end

    # A connection to the datasets redis db

    def redis
      @redis ||= Redis.new(Meda.configuration.redis.merge(:db => @rdb))
    end

    # A connection to the redis db 0 with meta data

    def self.redis_meta
      @redis_meta ||= Redis.new(Meda.configuration.redis.merge(:db => 0))
    end

    def zmembers_each(key, &block)
      redis.zrange(key, 0, -1).each do |i|
        block.call(i)
      end
    end

  end
end

