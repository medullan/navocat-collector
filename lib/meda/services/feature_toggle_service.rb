module Meda

  class FeatureToggleService

	attr_accessor :features
	
   	def initialize(featuresToggles)
      puts "Feature toggle config is #{featuresToggles}"
      @features = featuresToggles
    end

    def is_enabled(feature,default)
      if @features.nil? || @features.empty? || @features[feature].nil?
        return default
      end
 
      return @features[feature] == true  
    end

    def get_feature_service(feature)
      if @features.nil? || @features.empty? || @features[feature].nil?
        raise "missing features, cannot do #{feature} with #{@features}"
      end
 
      return @features[feature]  
    end

  end
end

