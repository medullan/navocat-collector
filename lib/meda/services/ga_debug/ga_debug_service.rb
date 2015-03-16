require 'logger'
require 'meda'
require 'meda/services/logging/logging_meta_data_service'

module Meda

  class GAHitDebugService

    def initialize(config)
      helperConfig = {}
      helperConfig["config"] = config
      @logging_meta_data_service = Meda::LoggingMetaDataService.new(helperConfig)
    end

    def debug_ga_response(ga_response)
      if !ga_response.blank?
        begin
          @logging_meta_data_service.add_to_mdc("ga_debug_validity", ga_response[:validity])
          @logging_meta_data_service.add_to_mdc("ga_debug_message", ga_response[:parser_message])
          @logging_meta_data_service.add_to_mdc_hash("ga_debug", ga_response[:params_sent_to_ga])
        rescue StandardError => e
          Meda.logger.error("Failure logging ga debug information")
          Meda.logger.error(e)
        end
      end
    end
  end
end