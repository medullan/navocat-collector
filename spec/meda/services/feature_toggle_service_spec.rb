require_relative '../../../lib/meda/services/feature_toggle_service'


describe Meda::FeatureToggleService do


  describe 'feature toggle service' do
    it 'returns true when toggle is on true' do
	 	featuresHash = {}
		featuresHash["trueFeature"] = true  	
      	feature_toggle_service = Meda::FeatureToggleService.new(featuresHash)	

		result = feature_toggle_service.is_enabled("trueFeature",true)
		expect(result).to be_true
    end

    it 'returns false when toggle is faLse' do
	 	featuresHash = {}
		featuresHash["falseFeature"] = false  	
      	feature_toggle_service = Meda::FeatureToggleService.new(featuresHash)	

		result = feature_toggle_service.is_enabled("falseFeature",true)
		expect(result).to be_false
    end

    it 'returns true when toggle is missing but default is true' do
	 	featuresHash = {}
			
      	feature_toggle_service = Meda::FeatureToggleService.new(featuresHash)	

		result = feature_toggle_service.is_enabled("trueFeature",true)
		expect(result).to be_true
    end

    it 'returns false when toggle is missing but default is false' do
	 	featuresHash = {}
			
      	feature_toggle_service = Meda::FeatureToggleService.new(featuresHash)	

		result = feature_toggle_service.is_enabled("missingFeature",false)
		expect(result).to be_false
    end


  end


end
