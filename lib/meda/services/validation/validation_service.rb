require 'logger'
require 'meda'

module Meda

  class ValidationService

    def valid_request?(client_id_cookie, request_params)
      if !client_id_cookie.blank? && !request_params[:dataset].blank?
        Meda.logger.debug("called with client_id: #{client_id_cookie} and dataset: #{request_params[:dataset]}")
        return true
      else
        Meda.logger.error("called with invalid client_id: #{client_id_cookie} or dataset #{request_params[:dataset]}")
        return false
      end
    end

    def valid_hit_request?(client_id_cookie, request_params)
      if valid_request?(client_id_cookie, request_params)
        if !request_params[:path].blank?
          Meda.logger.debug("call with path: #{request_params[:path]}")
          return true
        else
          Meda.logger.error("called with invalid path: #{request_params[:path]}")
          return false
        end
      end
      Meda.logger.error("valid_request? returned false")
      return false
    end

    def valid_profile_request?(client_id_cookie, request_params)
      if !request_params[:profile_id].blank?
        Meda.logger.debug("called with profile_id: #{request_params[:profile_id]}")
        return valid_request?(client_id_cookie, request_params)
      else
        Meda.logger.error("called with an empty profile_id: #{request_params[:profile_id]}")
        return false
      end
    end
  end
end