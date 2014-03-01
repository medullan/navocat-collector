require 'redis'
require 'ostruct'
require 'uuidtools'
require 'digest'
require 'csv'

module Meda
  class Dataset

    attr_reader :name

    def initialize(name, redis_db=0)
      @name = name
      @redis_db = redis_db
    end

    def test
      redis.set('test', 'hello world')
      puts redis.get('test')
    end

    def identify_user(info)
      user = find_or_create_user(info)
      return OpenStruct.new({
        :user_id => user['user_id'],
        :profile_id => user['profile_id']
      })
    end

    def add_event(event_props)
      event_props = event_props.dup
      event_info = {}
      event_info['name'] = event_props.delete('name') || raise('Event name required')
      event_info['profile_id'] = event_props.delete('profile_id') || raise('Profile id required')
      event_info['time'] = event_props.delete('time') || DateTime.now.to_s
      event_info['category'] = event_props.delete('none') || 'none'
      event_id = UUIDTools::UUID.timestamp_create.hexdigest
      profile = get_profile_by_id(event_info['profile_id'])
      hour = DateTime.parse(event_info['time']).strftime("%Y-%m-%d-%H:00:00")
      event_key = "new_events:#{hour}"
      redis.pipelined do
        redis.zadd('new_events', DateTime.parse(hour).to_f.to_s, event_key)
        redis.zadd(event_key, event_info['time'].to_f.to_s, event_id)
        redis.mapped_hmset("event:#{event_id}", event_info)
        if event_props.length > 0
          redis.mapped_hmset("event:#{event_id}:event_props", event_props)
        end
        if profile.attributes.length > 0
          redis.mapped_hmset("event:#{event_id}:profile_props", profile.attributes)
        end
      end
      event_id
    end

    def set_profile(profile_id, profile_info)
      redis.mapped_hmset("profile:#{profile_id}", profile_info)
    end

    def dump_to_disk(path)
      dump_events(File.join(path, 'events.csv', ))
      dump_event_props(File.join(path, 'event_props.csv'))
      dump_profile_props(File.join(path, 'profile_props.csv'))
    end

    # protected

    def dump_events(path)
      CSV.open(path, "wb") do |csv|
        csv << %w(event_id category name time)
        zmembers_each('new_events') do |new_event_range|
          zmembers_each(new_event_range) do |new_event_id|
            new_event = redis.hgetall("event:#{new_event_id}")
            csv << [
              new_event_id, new_event['category'], new_event['name'], new_event['time']
            ]
          end
        end
      end
    end

    def dump_event_props(path)
      CSV.open(path, "wb") do |csv|
        csv << %w(event_id key value numeric_value boolean_value)
        zmembers_each('new_events') do |new_event_range|
          zmembers_each(new_event_range) do |new_event_id|
            new_event = redis.hgetall("event:#{new_event_id}:event_props")
            new_event.each_pair do |key, val|
              csv << [
                new_event_id, key, val, val.to_f, !!val
              ]
            end
          end
        end
      end
    end

    def dump_profile_props(path)
      CSV.open(path, "wb") do |csv|
        csv << %w(event_id key value numeric_value boolean_value)
        zmembers_each('new_events') do |new_event_range|
          zmembers_each(new_event_range) do |new_event_id|
            new_event = redis.hgetall("event:#{new_event_id}:profile_props")
            new_event.each_pair do |key, val|
              csv << [
                new_event_id,
                Digest::SHA1.hexdigest(key),
                Digest::SHA1.hexdigest(val),
                val.to_f,
                !!val
              ]
            end
          end
        end
      end
    end

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

    def redis
      @redis ||= Redis.new(Meda.configuration.redis.merge(:db => @redis_db))
    end

    def zmembers_each(key, &block)
      redis.zrange(key, 0, -1).each do |i|
        block.call(i)
      end
    end

  end
end

