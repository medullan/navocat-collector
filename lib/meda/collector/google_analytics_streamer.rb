require 'uuidtools'

module Meda
  module Collector
    class GoogleAnalyticsStreamer

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
          sleep FLUSH_INTERVAL # unless there's another event, then just flush again
        end
      end

      def flush
        # puts 'Flushing to GA'
        # shift off the first hit from the ga queue
        # post to GA
        # on exception, unshift it back on to the queue
      end

      protected

      def redis
        @redis ||= Redis.new(Meda.configuration.redis.merge(:db => dataset.rdb))
      end

    end
  end
end

