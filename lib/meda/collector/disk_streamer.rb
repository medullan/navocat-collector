require 'uuidtools'

module Meda
  module Collector
    class DiskStreamer

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
          sleep FLUSH_INTERVAL
        end
      end

      def flush
        # puts 'Flushing to disk'
        # shift off the first range
        # read off and delete the new stuff
        # open file and write
        # close
        # on exception, add it back ...
      end

      protected

      def redis
        @redis ||= Redis.new(Meda.configuration.redis.merge(:db => dataset.rdb))
      end

    end
  end
end

