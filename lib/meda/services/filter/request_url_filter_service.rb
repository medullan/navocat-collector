require_relative "../profile/one_key/profile_id_service"

module Meda

  #abstracts profile service implementaton
  class RequestURLFilterService
	
   	def initialize(config)
      @profile_id_service = Meda::ProfileIdService.new(config)
    end

    def filter(url)
      without_member_id, member_id = url.split('member_id')
      profileIdHashInformation = {}
      profileIdHashInformation[:member_id] = member_id
      member_id_hashed = @profile_id_service.mapToHash(profileIdHashInformation)
      with_hashed_member_id = "#{without_member_id}member_id__hashed=#{member_id_hashed}"
      with_hashed_member_id
    end

  end
end

