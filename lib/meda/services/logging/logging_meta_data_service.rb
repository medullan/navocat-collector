require 'logging'
require 'json'
require 'uuidtools'
require_relative "../profile/one_key/profile_id_service"

module Meda

  class LoggingMetaDataService
	
	def features
      @features ||= Meda.features
    end

   	def initialize(config)
       @@request_url_filter_service = Meda::RequestURLFilterService.new(config)
       @profile_id_service = Meda::ProfileIdService.new(config)
    end

    def setup_meta_logs(request,headers,cookies,request_environment)

        hash = Hash.new()
        hash["request_uuid"] = UUIDTools::UUID.random_create.to_s
        hash["request_url"] = @@request_url_filter_service.filter(request)
        
        hash = hash.merge(cookies)
        hash = hash.merge(headers)
        hash["referrer"] = request.referrer
        hash["request_ip"] = Digest::SHA1.hexdigest(request_environment[:user_ip])
        hash["user_agent"] = request.user_agent
        hash["cache_control"] = request.env['HTTP_CACHE_CONTROL']
        hash = hash.merge(request.env['rack.request.query_hash']) if !request.env['rack.request.query_hash'].nil?
        hash["hashed_member_id"] = @profile_id_service.stringToHash(hash["member_id"]) if !hash["member_id"].nil? && hash["member_id"].length > 0
        hash.delete("member_id")
        
        Logging.mdc.clear
        Logging.mdc["meta_logs"] = hash.to_json
  
      end

  end
end



