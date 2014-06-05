module Meda
  module Collector
    class Connection

      DISK_POOL_DEFAULT = 1
      GA_POOL_DEFAULT = 1

      attr_reader :disk_pool, :ga_pool

      def initialize(options={})
        @options = options
        @disk_pool = options[:disk_pool] || Meda::WorkerPool.new({
          :size => Meda.configuration.disk_pool
        })
        @ga_pool = options[:ga_pool] || Meda::WorkerPool.new({
          :size => Meda.configuration.google_analytics_pool
        })

        Meda.datasets # pre-fetch

        at_exit do
          @disk_pool.shutdown
          @ga_pool.shutdown
        end
      end

      def identify(params)
        process_request(params) do |dataset, user_params|
          dataset.identify_profile(user_params)
        end
      end

      def profile(params)
        process_request(params) do |dataset, profile_params|
          profile_id = profile_params.delete(:profile_id)
          dataset.set_profile(profile_id, profile_params)
        end
        true
      end

      def track(params)
        params = get_user_id_for_logged_in_user(params)
        
        process_request(params) do |dataset, track_params|
          hit = dataset.add_event(track_params)
          disk_pool.submit do
            dataset.stream_hit_to_disk(hit)
          end
          if dataset.stream_to_ga?
            ga_pool.submit do
              dataset.stream_hit_to_ga(hit)
            end
          end
        end
        true
      end

      def page(params)
        params = get_user_id_for_logged_in_user(params)

        process_request(params) do |dataset, page_params|
          hit = dataset.add_pageview(page_params)
          disk_pool.submit do
            dataset.stream_hit_to_disk(hit)
          end
          if dataset.stream_to_ga?
            ga_pool.submit do
              dataset.stream_hit_to_ga(hit)
            end
          end
        end
        true
      end

      def get_user_id_for_logged_in_user(params)
        if(params[:profile_id] !=  '351bb960ecd711e3a0a822000ab93e79')
          params[:user_id] = params[:profile_id]
        end
        params
      end

      def join_threads(&block)
        while @disk_pool.active? || @ga_pool.active? do
        end
        yield if block_given?
      end

      protected

      def process_request(params, &block)
        begin
          dataset, other_params = extract_dataset_from_params(params)
          yield(dataset, other_params) if block_given?
        rescue StandardError => e
          Meda.logger.error(e) if Meda.logger
          puts e
          raise e
        end
      end

      def extract_dataset_from_params(params)
        if params[:dataset].blank?
          raise 'Cannot find dataset. Token param blank.'
        end
        extra_params = params.symbolize_keys
        token = extra_params.delete(:dataset)
        dataset = Meda.datasets[token]
        if dataset
          return dataset, extra_params
        else
          raise "No dataset found for token param #{token}"
        end
      end

    end
  end
end

