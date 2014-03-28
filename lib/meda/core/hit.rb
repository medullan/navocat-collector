module Meda
  class Hit < Struct.new(:name, :time, :profile_id, :props)

    attr_accessor :profile_props, :id

    def initialize(props)
      name = props.delete(:name)
      time = props.delete(:time)
      profile_id = props.delete(:profile_id)
      profile_props = {}
      super(name, time, profile_id, props)
    end

    def hit_type
      nil
    end

    def hit_type_plural
      nil
    end

    def validate!
      raise('Hit name is required') if name.blank?
      raise('Hit time is required') if time.blank?
      # raise('Hit profile id is required') if profile_id.blank?
    end

    def hour
      DateTime.parse(time).strftime("%Y-%m-%d-%H:00:00")
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
        :name => name,
        :time => time,
        :props => props,
        :profile_id => profile_id,
        :profile_props => profile_props
      }
    end

    def as_ga_json
      props.merge({
        :client_id => profile_id,
        :cache_buster => id
      })
    end

    def to_json
      as_json.to_json
    end

    def to_ga_json
      as_ga_json.to_json
    end

  end
end

