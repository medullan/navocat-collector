
module Meda

#TODO use fowardable?
  class ProfileService
	
	def features
      @features ||= Meda.features
    end

   	def initialize(config)
      @loggers = []
      @level = config.log_level || Logger::INFO

      @loggers.push(setup_file_logger(config)) if setup_file_logger(config)
      @loggers.push(setup_console_logger(config)) if setup_console_logger(config)
      @loggers.push(setup_loggly_logger(config)) if setup_loggly_logger(config)
      @loggers.push(setup_postgres_logger(config))   if setup_postgres_logger(config)
      @loggers.each do |logger|
        puts @logger
      end

      puts "#{@loggers.length.to_s} loggers have been setup"
    end


  end
end



