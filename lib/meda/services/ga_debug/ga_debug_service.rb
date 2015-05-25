require 'json'
require 'logger'
require 'meda'
require 'meda/services/logging/logging_meta_data_service'
require 'meda/services/verification/request_verification_service'

module Meda

  class GAHitDebugService

    def initialize()
      helperConfig = {}
      helperConfig["config"] = Meda.configuration
      @logging_meta_data_service = Meda::LoggingMetaDataService.new(helperConfig)
      @@request_verification_service = Meda::RequestVerificationService.new(helperConfig["config"])
    end

    def debug_ga_info(debug_ga_response)
      begin
        ga_response_json = debug_ga_response[:ga_response_json]
        ga_response_code = debug_ga_response[:ga_response_code]
        params_sent_to_ga = debug_ga_response[:params_sent_to_ga]

        @logging_meta_data_service.add_to_mdc("ga_debug_response_code", ga_response_code)

        if !ga_response_json.blank?
          ga_response_json = parse_ga_response(ga_response_json)
          @logging_meta_data_service.add_to_mdc_hash("ga_debug_raw_json", ga_response_json)

          if !params_sent_to_ga.blank? && ga_response_code == "200"
            ga_response = construct_ga_debug_object(ga_response_json)
            if Meda.features.is_enabled("verification_api", false)
              ga_data = ga_response_json.merge(ga_response).merge({:response_code => ga_response_code}).merge(params_sent_to_ga)
              @@request_verification_service.add_ga_data(ga_data)
            end
            @logging_meta_data_service.add_to_mdc("ga_debug_validity", ga_response[:validity])
            @logging_meta_data_service.add_to_mdc("ga_debug_message", ga_response[:parser_message])
            @logging_meta_data_service.add_to_mdc_hash("ga_debug", params_sent_to_ga)
          end
        end

      rescue StandardError => e
        msg = "Failure logging ga debug information"
        Meda.logger.error(msg)
        Meda.logger.error(e)
        data = {:message => e.message, :status=> 500, :status_text=> 'Internal Error', :log_msg => msg}
        @@request_verification_service.end_rva_log(data)
      end
    end

    def construct_ga_debug_object(ga_response_json)
      @response_hash = {:validity => nil,
                        :parser_message => nil}

      if !ga_response_json.blank? && validate_json_array(ga_response_json)
        validity = ga_response_json['hit_parsing_result'][0]['valid']
        parser_message = ga_response_json['hit_parsing_result'][0].to_a.join("--")

        @response_hash = {:validity => validity,
                          :parser_message => parser_message}

      end
      @response_hash
    end

    def validate_json_array(json_array)
      if !json_array.blank? && !json_array['hit_parsing_result'].blank? && !json_array['hit_parsing_result'][0].blank?
        return true
      else
        return false
      end
    end

    def parse_ga_response(ga_response_json)
      begin
        if !ga_response_json.blank?
          ga_response_json = JSON.parse(ga_response_json)
        end
        ga_response_json
      rescue StandardError => e
        Meda.logger.error("Failure to parse json object")
        Meda.logger.error(e)
      end
    end
  end
end