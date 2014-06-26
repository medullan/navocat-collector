require 'meda/core/hit'

module Meda

  # Represents a pageview type analytics hit
  class Pageview < Meda::Hit

    def hit_type
      'pageview'
    end

    def hit_type_plural
      'pageviews'
    end
  end
end

