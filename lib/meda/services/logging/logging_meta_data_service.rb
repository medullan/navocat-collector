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
        hash["request_url_path"] = request.path_info
        hash["referrer"] = request.referrer
        hash["referer"] = request.referer
        hash["request_ip"] = Digest::SHA1.hexdigest(request_environment[:user_ip])
        hash["user_agent"] = request.user_agent
        hash["rack_cache_control"] = request.env['HTTP_CACHE_CONTROL']
        hash["rack_remote_address"] = Digest::SHA1.hexdigest(request.env['REMOTE_ADDR'].split(',').first)
        
        cookies_hash = prefix_hash("cookie",cookies) 
        hash = hash.merge(cookies_hash)

        header_hash = prefix_hash("header",headers) 
        hash = hash.merge(header_hash)
        
        query_string_hash = prefix_hash("querystring",request.env['rack.request.query_hash']) if !request.env['rack.request.query_hash'].nil?
        hash = hash.merge(query_string_hash) if !query_string_hash.nil?

        hash["hashed_member_id"] = @profile_id_service.stringToHash(hash["querystring_member_id"]) if !hash["querystring_member_id"].nil? && hash["querystring_member_id"].length > 0
        
        prefixes = []
        prefixes.push("cookie")
        prefixes.push("header")
        prefixes.push("querystring")

        hash = delete_with_prefixes(prefixes,"member_id",hash)
        hash = delete_with_prefixes(prefixes,"COMPANY_ID",hash)
        hash = delete_with_prefixes(prefixes,"ID",hash)
        hash = delete_with_prefixes(prefixes,"PASSWORD",hash)
        hash = delete_with_prefixes(prefixes,"LOGIN",hash)
        hash = delete_with_prefixes(prefixes,"SCREEN_NAME",hash)
        hash = delete_with_prefixes(prefixes,"fepblue#lang",hash)
        hash = delete_with_prefixes(prefixes,"views",hash)
        hash = delete_with_prefixes(prefixes,"SC_ANALYTICS_GLOBAL_COOKIE",hash)
        hash = delete_with_prefixes(prefixes,"_ga",hash)
        hash = delete_with_prefixes(prefixes,"_gat",hash)
        hash = delete_with_prefixes(prefixes,"SC_ANALYTICS_SESSION_COOKIE",hash)
        hash = delete_with_prefixes(prefixes,"BIPApp",hash)
        hash = delete_with_prefixes(prefixes,"BIPCore",hash)
        hash = delete_with_prefixes(prefixes,"starts",hash)
        hash = delete_with_prefixes(prefixes,"alert-expires",hash)
        hash = delete_with_prefixes(prefixes,"i18next",hash)

        Logging.mdc.clear
        Logging.mdc["meta_logs"] = hash.to_json
       
    end


    def prefix_hash(prefix,hash)
        if hash.nil? 
            return nil
        end

        prefix_hash = Hash.new()

        hash.keys.each { |key| 
            prefix_hash[prefix+'_'+key] = hash[key]
        } 

        prefix_hash
    end

    def delete_with_prefixes(prefixes, key, hash)
        if hash.nil? 
            return nil
        end

        prefixes.each { |prefix|
            hash.delete(prefix+'_'+key)
        }

        hash

    end

  end
end



