module Meda

  class FeatureToggleService

	attr_accessor :features
	
   	def initialize(featuresToggles)
      puts "featuresToggles #{featuresToggles}"
      @features = featuresToggles
    end

    def is_enabled(feature,default)
      if @features.nil? || @features.empty?
        return default
      end

      return @features[feature] == true  
    end

  end
end

