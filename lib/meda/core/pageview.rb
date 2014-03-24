require 'meda/core/hit'

module Meda
  class Pageview < Meda::Hit

    def hit_type
      'pageview'
    end

    def hit_type_plural
      'pageviews'
    end
  end
end

