require_relative '../../../lib/meda/services/feature_toggle_service'


describe Meda::FeatureToggleService do


  describe 'feature toggle service' do
    it 'returns true when toggle is on true' do
	 	featuresHash = {}
		featuresHash["trueFeature"] = true  	
      	feature_toggle_service = Meda::FeatureToggleService.new(featuresHash)	

		result = feature_toggle_service.is_enabled("trueFeature",true)
		expect(result).to be_truthy
    end

    it 'returns false when toggle is faLse' do
	 	featuresHash = {}
		featuresHash["falseFeature"] = false  	
      	feature_toggle_service = Meda::FeatureToggleService.new(featuresHash)	

		result = feature_toggle_service.is_enabled("falseFeature",true)
		expect(result).to be_falsey
    end

    it 'returns true when toggle is missing but default is true' do
	 	featuresHash = {}
			
      	feature_toggle_service = Meda::FeatureToggleService.new(featuresHash)	

		result = feature_toggle_service.is_enabled("trueFeature",true)
		expect(result).to be_truthy
    end

    it 'returns false when toggle is missing but default is false' do
	 	featuresHash = {}
			
      	feature_toggle_service = Meda::FeatureToggleService.new(featuresHash)	

		result = feature_toggle_service.is_enabled("missingFeature",false)
		expect(result).to be_falsey
    end

    it 'raises exception when features do not exist' do
    	featuresHash = {}
    	feature_toggle_service = Meda::FeatureToggleService.new(featuresHash)	
    	expect { feature_toggle_service.get_feature_service("feature") }.to raise_error
    end

    it 'raises exception when features does not include requested feature' do
    	featuresHash = {}
    	featuresHash["falseFeature"] = false  
    	feature_toggle_service = Meda::FeatureToggleService.new(featuresHash)	
    	expect { feature_toggle_service.get_feature_service("feature") }.to raise_error
    end

    it 'returns feature to use when it exists' do
    	featuresHash = {}
    	feature = "profile_store"
    	feature_service = "mapdb"
    	featuresHash[feature] = feature_service  
    	feature_toggle_service = Meda::FeatureToggleService.new(featuresHash)	
    	result = feature_toggle_service.get_feature_service(feature)
    	expect(result).to eq(feature_service) 
    end

  end


end
