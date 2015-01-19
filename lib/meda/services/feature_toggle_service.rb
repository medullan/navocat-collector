module Meda

  class FeatureToggleService

	attr_accessor :features
	
   	def initialize(featuresToggles)
      @@features = featuresToggles
    end


  	def is_enabled(feature)
  		if @@features.nil? || @@features.empty?
        return true
      end

      if @@features[feature] == false
        return false
      end

      #default to features on.
      return true  
  	end

  end
end

