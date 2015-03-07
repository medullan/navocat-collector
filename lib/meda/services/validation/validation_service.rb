require 'logger'
require 'meda'

module Meda

  class ValidationService

    def valid_request?(client_id_cookie, request_params)
      if !client_id_cookie.nil? && client_id_cookie != '' && !request_params[:dataset].nil? && request_params[:dataset] != ''
        Meda.logger.info("#{__method__} was called with client_id: #{client_id_cookie} and dataset: #{request_params[:dataset]}")
        return true
      else
        Meda.logger.error("#{__method__} was called with invalid client_id: #{client_id_cookie} or dataset: #{__method__} was called from #{__callee__}")
        return false
      end
    end

    def valid_hit_request?(client_id_cookie, request_params)
      if valid_request?(client_id_cookie, request_params)
        if !request_params[:path].nil? && !request_params[:path].empty?
          Meda.logger.info("#{__method__} was call with path: #{request_params[:path]}")
          return true
        else
          Meda.logger.error("#{__method__} was called with invalid path: #{request_params[:path]}")
          return false
        end
      end
      Meda.logger.error("#{__method__}: valid_request? returned false")
      return false
    end
  end
end