require_relative "../profile/one_key/profile_id_service"

module Meda

  #abstracts profile service implementaton
  class RequestURLFilterService
	
   	def initialize(config)
      @profile_id_service = Meda::ProfileIdService.new(config)
    end

    #todo : update to use actual url
    def filter(request)
         
      request_path = request.env['REQUEST_PATH']
      url = request.url
  	  if(!request_path.nil? && !request_path.end_with?('/identify.gif'))
  	  	return url
  	  end

      url = request.url
      member_id = request.params["member_id"]

      if(member_id.nil? || member_id.length == 0)
      	return url
      end

      profileIdHashInformation = {}
      profileIdHashInformation[:member_id] = member_id
      member_id_hashed = @profile_id_service.mapToHash(profileIdHashInformation)

      url = url.gsub "member_id", "member_id__hashed"
      url = url.gsub member_id, member_id_hashed

      url

    end

  end
end

