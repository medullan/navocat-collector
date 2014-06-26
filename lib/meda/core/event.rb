require 'meda/core/hit'

module Meda

  # Represents an "event" type analytics hit.
  class Event < Meda::Hit

    def hit_type
      'event'
    end

    def hit_type_plural
      'events'
    end
  end
end

