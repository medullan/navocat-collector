require 'logger'
require 'meda'

module Meda

  class ValidationService

    def initialize()

    end

    def valid_request?(request_params)
      if !request_params[:dataset].nil? && request_params[:dataset] != ''
        Meda.logger.info("#{__method__} was called with dataset set to #{request_params[:dataset]}")
        return true
      else
        Meda.logger.error("#{__method__} was called with empty dataset, #{__method__} was called from #{__callee__}")
        return false
      end
    end

    def valid_hit_request?(request_params)
      if valid_request?(request_params)
        if !request_params[:client_id].nil? && request_params[:client_id] != '' && !request_params[:path].nil? && request_params[:path] != ''
          Meda.logger.info("#{__method__} was call with client_id: #{request_params[:client_id]} and path: #{request_params[:path]}")
          return true
        else
          Meda.logger.error("#{__method__} was called with invalid values, client_id: #{request_params[:client_id]}, path: #{request_params[:path]}")
          return false
        end
      end
    end
  end
end