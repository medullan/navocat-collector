module Meda
  module Collector
    class Connection

      RDB = 0

      def initialize(options={})
        @options = options
      end

      def identify(params)
        dataset = get_dataset_from_params(params)
        dataset.identify_user(params)
      end

      def profile(params)
        dataset = get_dataset_from_params(params)
        id = params.delete('profile_id')
        dataset.set_profile(id, params)
      end

      def event(params)
        dataset = get_dataset_from_params(params)
        dataset.add_event(params)
      end

      def create_dataset(dataset_name, rdb_index)
      end

      def destroy_dataset(dataset_name)
      end

      protected

      def get_dataset_from_params(params)

        return Meda::Dataset.new('day_members', 1);

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

      def get_dataset_by_name
        # find in redis and return dataset object
      end

      def get_dataset_by_token
        # find in redis and return dataset object
      end

      def redis
        @redis ||= Redis.new(Meda.configuration.redis.merge(options[:redis]).merge(:db => RDB))
      end

    end
  end
end

