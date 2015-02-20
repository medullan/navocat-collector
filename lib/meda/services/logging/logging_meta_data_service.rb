require 'logging'
require 'json'
require 'uuidtools'

module Meda

  class LoggingMetaDataService
	
	def features
      @features ||= Meda.features
    end

   	def initialize(config)
       @@request_url_filter_service = Meda::RequestURLFilterService.new(config)
    end

    def setup_meta_logs(request,headers,cookies)

      hash = Hash.new()
      hash["request_uuid"] = UUIDTools::UUID.random_create.to_s
      hash["request_url"] = @@request_url_filter_service.filter(request.url)
      hash = hash.merge(cookies)
      hash = hash.merge(headers)
      hash["referrer"] = request.referrer
      hash["request_ip"] = Digest::SHA1.hexdigest(request.ip)
     
      Logging.mdc.clear
      Logging.mdc["meta_logs"] = hash.to_json
  
      end

  end
end



