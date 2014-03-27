require 'uuidtools'

module Meda
  module Collector
    class DiskStreamer

      attr_reader :dataset, :uuid
      attr_accessor :stop

      FLUSH_INTERVAL = 5 # second
      DATA_PATH = 'data'

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
        flush_hits('new_events', 'events')
        flush_hits('new_pageviews', 'pageviews')
      end

      protected

      def flush_hits(new_hits_key, hit_path)
        new_hits_ranges = redis.zrange(new_hits_key, 0, -1)
        redis.del(new_hits_key)

        new_hits_ranges.each do |new_hit_range|
          begin
            hour = new_hit_range.split(':')[1..-1].join(':')
            day = hour[0..9]
            data_path = Meda.configuration.data_path || DATA_PATH
            directory = File.join(data_path, hit_path, day)
            filename = "#{hour}-#{uuid}.json"
            path = File.join(directory, filename)
            FileUtils.mkdir_p(directory)
            output = redis.zrange(new_hit_range, 0, -1).join("\n")
            File.open(path, 'a') do |f|
              f.puts(output)
            end
            redis.del(new_hit_range)
            logger.info "Wrote to #{path}"
          rescue StandardError => e
            # If write fails, put the range back and try again later
            logger.error("Failed to write #{new_hit_range}")
            logger.error(e)
            redis.zadd(new_hits_key, 1, new_hit_range) # need to put score back too...
            raise e
          end
        end
        true
      end

      def redis
        @redis ||= Redis.new(Meda.configuration.redis.merge(:db => dataset.rdb))
      end

      def logger
        if @logger.nil? && Meda.configuration.log_path.present?
          FileUtils.mkdir_p(File.dirname(Meda.configuration.log_path))
          FileUtils.touch(Meda.configuration.log_path)
          @logger = Logger.new(Meda.configuration.log_path)
          @logger.level = Meda.configuration.log_level || Logger::INFO
        end
        @logger
      end

    end
  end
end

