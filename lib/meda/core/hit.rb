
require 'uuidtools'



module Meda

  # Each hit represents a single user activity, a pageview, event, etc.
  # A hit's JSON representation is written to disk and to GA.

  class Hit < Struct.new(:time, :profile_id, :client_id, :props)

    attr_accessor :profile_props, :id, :dataset, :default_profile_id, :tracking_id, :is_invalid, :request_id

    def initialize(props, default_profile_id, dataset)
      @id = UUIDTools::UUID.timestamp_create.hexdigest
      @tracking_id = dataset.google_analytics['tracking_id'] if (dataset && dataset.google_analytics)
      time = props.delete(:time)
      profile_id = props.delete(:profile_id)
      client_id = props.delete(:client_id)
      @default_profile_id = default_profile_id
      @dataset = dataset
      profile_props = {}
      super(time, profile_id, client_id, props)
      add_extra_props
    end

    def hit_type
      nil
    end

    def hit_type_plural
      nil
    end

    def validate!
      raise('Hit time is required') if time.blank?
    end

    def hour
      DateTime.parse(time).strftime("%Y-%m-%d-%H:00:00")
    end

    def day
      DateTime.parse(time).strftime("%Y-%m-%d")
    end

    def hour_value
      DateTime.parse(hour).to_f
    end

    def time_value
      DateTime.parse(time).to_f
    end

    def as_json
      {
        :id => id,
        :ht => time,
        :hp => props,
        :pi => profile_id,
        :ci => client_id,
        :pp => profile_props
      }
    end

    def add_extra_props
      if(profile_id != default_profile_id)
        props[:user_id] = profile_id
      end      
      props[:cache_buster] = id
      props[:anonymize_ip] = 1
    end

    def as_ga
      props
    end

    def to_json
      as_json.to_json
    end

    def to_ga_json
      as_ga.to_json
    end

  end
end

