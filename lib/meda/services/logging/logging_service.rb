require 'logger'
require 'json'

module Meda

#TODO use fowardable?
  class LoggingService
	
	def features
      @features ||= Meda.features
    end

   	def initialize(config)
      @loggers = []
      @level = config.log_level || Logger::INFO

      @loggers.push(setup_file_logger(config))
      @loggers.push(setup_console_logger(config))
      @loggers.push(setup_loggly_logger(config))
      @loggers.push(setup_postgres_logger(config))   
    end

    def setup_file_logger(config)
      FileUtils.mkdir_p(File.dirname(config.log_path))
      FileUtils.touch(config.log_path)
      loggingLevel = config.log_level || Logger::INFO
      @fileLogger = Logger.new(config.log_path)
      @fileLogger.formatter = proc do |severity, datetime, progname, msg|
         "#{msg}\n"
      end

      puts "file logger setup at #{config.log_path}"
      @fileLogger
    end

    def setup_console_logger(config)
      loggingLevel = config.log_level || Logger::INFO
      @consoleLogger = Logger.new(STDOUT)
      @consoleLogger.formatter = proc do |severity, datetime, progname, msg|
         "#{msg}\n\n"
      end
      @consoleLogger
    end

    def setup_loggly_logger(config)
      require 'logglier' 
      @logglyLogger = Logglier.new("https://logs-01.loggly.com/inputs/d3edcdea-6c63-446a-a60b-4cb7db999d55/tag/ruby/", :format => :json,:threaded => true) 
      @logglyLogger
    end

    def setup_postgres_logger(config)
      require_relative 'postgres_logging_service.rb' 
      @postgres_logger = Meda::PostgresLoggingService.new(config)
      puts "postgres logger setup"
      @postgres_logger
    end

  	def error(message)
  		message = add_meta_data(message,"error")
  		 @loggers.each do |logger|
        logger.error(message)  
       end
  	end

  	def warn(message)
  		if @level <= 2
	  		message = add_meta_data(message,"warn")
        @loggers.each do |logger|
          logger.warn(message)  
       end
  		end
  	end


  	def info(message)	
  		if @level <= 1
	  		message = add_meta_data(message,"info")
	  		
      @loggers.each do |logger|
          logger.info(message)  
       end
  		end
  	end


  	def debug(message)
		if @level <= 0
	  		message = add_meta_data(message,"debug")

        @loggers.each do |logger|
          logger.debug(message)  
       end
  		end
  	end

  	def add_meta_data(message,severity)

      hash = Hash.new();
      hash["message"] = JSON.generate(message, quirks_mode: true)
      hash["file"] = caller.second.split(":in")
      hash["request id"] = Thread.current[:request_uuid]
      hash["severity"] = severity
      hash["timestamp"] = Time.now
      hash["thread"] = Thread.current.object_id.to_s
		
  		if message.is_a? StandardError
  			hash["stacktrace"] = message.backtrace
  		end

      hash.to_json
  	end	



  end
end



