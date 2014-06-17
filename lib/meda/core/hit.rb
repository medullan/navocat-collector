module Meda
  class Hit < Struct.new(:time, :profile_id, :props, :client_id)

    attr_accessor :profile_props, :id, :dataset

    def initialize(props)
      time = props.delete(:time)
      profile_id = props.delete(:profile_id)
      client_id = props.delete(:client_id)
      profile_props = {}
      super(time, profile_id, props, client_id)
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
        :pp => profile_props
      }
    end

    def as_ga
      props.merge({
        :client_id => client_id,
        :cache_buster => id,
        :anonymize_ip => 1,
        :user_id => profile_id
      })
    end

    def to_json
      as_json.to_json
    end

    def to_ga_json
      as_ga.to_json
    end

  end
end

