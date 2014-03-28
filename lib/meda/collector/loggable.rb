require 'logger'

module Meda
  module Collector
    module Loggable

      def logger
        if @logger.nil? && Meda.configuration.log_path.present?
          FileUtils.mkdir_p(File.dirname(Meda.configuration.log_path))
          FileUtils.touch(Meda.configuration.log_path)
          @logger = Logger.new(Meda.configuration.log_path)
          @logger.level = Meda.configuration.log_level || Logger::INFO
        end
        @logger
      end

    end
  end
end

