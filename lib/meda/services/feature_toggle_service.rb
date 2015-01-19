module Meda

  class FeatureToggleService

	attr_accessor :features
	
   	def initialize(featuresToggles)
      puts "featuresToggles #{featuresToggles}"
      @features = featuresToggles
    end

    def is_enabled(feature,default)
      puts "test feature #{feature}, default #{default}"
      if @features.nil? || @features.empty?
        puts "no features, return default"
        return default
      end

      return @features[feature] == true  
    end

  end
end

