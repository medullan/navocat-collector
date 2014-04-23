require 'redis'
require 'ostruct'
require 'uuidtools'
require 'digest'
require 'csv'
require 'securerandom'
require 'staccato'

module Meda
  class Dataset

    attr_reader :data_uuid, :name
    attr_accessor :google_analytics, :rdb, :token

    def initialize(name, rdb=1)
      @name = name
      @rdb = rdb
      @data_uuid = UUIDTools::UUID.timestamp_create.hexdigest
      @data_paths = {}
      @after_identify = lambda {|dataset, user| }
    end

    def identify_user(info)
      user_hash = find_or_create_user(info)
      user = OpenStruct.new({
        :user_id => user_hash['user_id'],
        :profile_id => user_hash['profile_id']
      })
      @after_identify.call(self, user)
      return user
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
        hit.profile_props = profile.attributes.clone
      else
        # Hit has no profile
        # Leave it anonymous-ish for now. Figure out what to do later.
      end

      hit.validate! # blows up if missing attrs
      hit
    end

    def stream_to_ga?
      !!google_analytics['record']
    end

    def stream_hit_to_disk(hit)
      data_path = Meda.configuration.data_path
      directory = File.join(data_path, hit.hit_type_plural, hit.day) # i.e. 'meda_data/events/2014-04-01'
      unless @data_paths[directory]
        # create the data directory if it does not exist
        @data_paths[directory] = FileUtils.mkdir_p(directory)
      end
      filename = "#{hit.hour}-#{self.data_uuid}.json"
      path = File.join(directory, filename)
      begin
        File.open(path, 'a') do |f|
          f.puts(hit.to_json)
        end
      rescue StandardError => e
        Meda.logger.error("Failure writing hit #{hit.id} to #{path}")
        Meda.logger.error(e)
        raise e
      end
      true
    end

    def stream_hit_to_ga(hit)
      return unless stream_to_ga?
      tracker = Staccato.tracker(google_analytics['tracking_id'], hit.profile_id)
      begin
        if hit.hit_type == 'pageview'
          ga_hit = Staccato::Pageview.new(tracker, hit.as_ga)
        elsif hit.hit_type == 'event'
          ga_hit = Staccato::Event.new(tracker, hit.as_ga)
        end
        google_analytics['custom_dimensions'].each_pair do |dim, val|
          ga_hit.add_custom_dimension(val['index'], dim)
        end
        ga_hit.track!
      rescue StandardError => e
        Meda.logger.error("Failure writing hit #{hit.id} to GA")
        Meda.logger.error(e)
        raise e
      end
      true
    end

    def set_profile(profile_id, profile_info)
      redis do |r|
        r.mapped_hmset("profile:#{profile_id}", profile_info)
      end
      puts "set profile vars #{profile_info}"
    end

    def after_identify(&block)
      @after_identify = block
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
      redis do |r|
        r.hgetall("user:#{user_id}")
      end
    end

    def get_profile_by_id(profile_id)
      redis do |r|
        profile_info = r.hgetall("profile:#{profile_id}")
        Meda::Profile.new(self, profile_info)
      end
    end

    # Uses one criteria at a time, in order, until a unique match is found

    def lookup_user(info)
      lookup_keys = info.map{|k,v| hashed_user_lookup_key(k,v)}
      user_id = nil
      user_ids = nil
      test_keys = []
      while (user_id.nil? && lookup_keys.length > 0) do
        test_keys << lookup_keys.shift
        redis do |r|
          user_ids = r.sinter(test_keys)
        end
        user_id = user_ids.first if user_ids.length == 1
      end
      user_id
    end

    def create_user(info)
      user_info = {
        'user_id' => UUIDTools::UUID.timestamp_create.hexdigest,
        'profile_id' => UUIDTools::UUID.timestamp_create.hexdigest
      }.merge(info)

      redis do |r|
        r.pipelined do |rp|
          rp.mapped_hmset("user:#{user_info['user_id']}", user_info)
          user_info.each_pair{|k, v| rp.sadd(hashed_user_lookup_key(k,v), user_info['user_id'])}
        end
      end
      return user_info
    end

    def hashed_user_lookup_key(k,v)
      "user:lookup:#{Digest::SHA1.hexdigest(k.to_s)}:#{Digest::SHA1.hexdigest(v.to_s)}"
    end

    def redis(&block)
      Meda.redis.with do |conn|
        conn.select(@rdb)
        yield(conn) if block_given?
      end
    end

  end
end

