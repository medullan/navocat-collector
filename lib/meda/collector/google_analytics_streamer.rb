require 'uuidtools'
require 'staccato'
require 'meda/collector/loggable'

module Meda
  module Collector
    class GoogleAnalyticsStreamer

      include Meda::Collector::Loggable

      attr_reader :dataset, :uuid
      attr_accessor :stop

      FLUSH_INTERVAL = 5 # second

      def initialize(dataset)
        @dataset = dataset
        @uuid = UUIDTools::UUID.timestamp_create.hexdigest
      end

      def run
        until Thread.current[:should_exit]
          flush
        end
      end

      def flush
        pageview_result = flush_pageview('ga_new_pageviews')
        event_result = flush_event('ga_new_events')
        if pageview_result.nil? && event_result.nil?
          sleep FLUSH_INTERVAL
        end
        true
      end

      protected

      def flush_pageview(ga_hits_key)
        hit_json = redis.lpop(ga_hits_key)
        return nil if hit_json.nil?

        begin
          hit = JSON.parse(hit_json).symbolize_keys
          tracker = Staccato.tracker(dataset.ga_account, hit[:client_id])
          tracker.pageview(hit)
        rescue StandardException => e
          redis.lpush(ga_hits_key, hit_json) # something went wrong, put it back
          logger.error("Failed to write hit to GA")
          logger.error(e)
          raise e
        end
      end

      def flush_event(ga_hits_key)
        hit_json = redis.lpop(ga_hits_key)
        return nil if hit_json.nil?

        begin
          hit = JSON.parse(hit_json).symbolize_keys
          tracker = Staccato.tracker(dataset.ga_account, hit[:client_id])
          tracker.event(hit)
        rescue StandardError => e
          redis.lpush(ga_hits_key, hit_json)
          logger.error("Failed to write hit to GA")
          logger.error(e)
          raise e
        end
      end

      def redis
        @redis ||= Redis.new(Meda.configuration.redis.merge(:db => dataset.rdb))
      end

    end
  end
end

