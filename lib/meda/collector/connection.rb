require 'meda/collector/disk_streamer'
require 'meda/collector/google_analytics_streamer'

module Meda
  module Collector
    class Connection

      class StreamerThread < Thread
      end

      RDB = 0

      def initialize(options={})
        @options = options
        @disk_threads = []
        @ga_threads = []

        at_exit do
          stop_streams
        end
      end

      def identify(params)
        dataset, user_params = extract_dataset_from_params(params)
        dataset.identify_user(params)
      end

      def profile(params)
        dataset, profile_params = extract_dataset_from_params(params)
        profile_id = profile_params.delete(:profile_id)
        dataset.set_profile(profile_id, profile_params)
      end

      def track(params)
        dataset, track_params = extract_dataset_from_params(params)
        dataset.add_event(track_params)
      end

      def page(params)
        dataset, page_params = extract_dataset_from_params(params)
        dataset.add_pageview(page_params)
      end

      def datasets
        @datasets ||= Meda::Dataset.all
      end

      def create_dataset(dataset_name, rdb_index)
        @datasets = nil
        Meda::Dataset.create(dataset_name, rdb_index)
      end

      def destroy_dataset(dataset_name)
        @datasets = nil
        Meda::Dataset.destroy(dataset_name)
      end

      def start_disk_streams
        puts '* Starting Meda disk streamers'

        datasets.each do |dataset|
          disk_stream = Meda::Collector::DiskStreamer.new(dataset)
          @disk_threads << StreamerThread.new { disk_stream.run }
        end
        true
      end

      def start_ga_streams
        return
        puts '* Starting Meda Google Analytics streamers'

        datasets.each do |dataset|
          ga_stream = Meda::Collector::GoogleAnalyticsStreamer.new(dataset)
          @ga_threads << StreamerThread.new { ga_stream.run }
        end
        true
      end

      def stop_streams
        @disk_threads.each {|t| t[:should_exit] = true }
        @ga_threads.each {|t| t[:should_exit] = true }
      end

      protected

      def extract_dataset_from_params(params)
        extra_params = params.symbolize_keys
        dataset_name = extra_params.delete(:dataset)
        token = extra_params.delete(:token)

        return Meda::Dataset.new('test', 1), extra_params

        # if params[:dataset].present?
        #   dataset = get_dataset_by_name(params[:dataset])
        # elsif params[:token].present?
        #   dataset = get_dataset_by_token(params[:token])
        # else
        #   raise ('Dataset not found')
        # end
        # raise ('Dataset not found') if dataset.nil?
        # dataset
      end

      def get_dataset_by_name(name)
        # find in redis and return dataset object
        id = redis.get("dataset:lookup:name:#{name}")
        if dataset_id
          rdb = redis.hget("dataset:#{id}", rdb)
          Meda::Dataset.new(name, rdb)
        end
      end

      def get_dataset_by_token(token)
        id = redis.get("dataset:lookup:token:#{token}")
        if dataset_id
          rdb = redis.hget("dataset:#{id}", rdb)
          Meda::Dataset.new(name, rdb)
        end
      end

      def redis
        @redis ||= Redis.new(Meda.configuration.redis.merge(options[:redis]).merge(:db => RDB))
      end

    end
  end
end

