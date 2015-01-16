require 'logglier' 
require 'logger'

module Meda

#TODO use fowardable?
  class LoggingService

	attr_accessor :level, :log, :nativelogger
	
   	def initialize(log_path,level)

      	@logglyLogger = Logglier.new("https://logs-01.loggly.com/inputs/d3edcdea-6c63-446a-a60b-4cb7db999d55/tag/ruby/", :format => :json) 
		@consoleLogger = Logger.new(STDOUT)
      	@fileLogger = Logger.new(log_path)
      
      	@consoleLogger.level = level
      	@fileLogger.level = level
      	@level = level

      	puts "logging level is #{@level}"
      	puts "logging file location is #{log_path}"
      	
    end

  	def error(message)
  		message = add_meta_data(message)
		@logglyLogger.error(message)  
		@consoleLogger.error(message)
		@fileLogger.error(message)
  	end

  	def warn(message)
  		if @level >= 2
	  		message = add_meta_data(message)
			@logglyLogger.warn(message)  
			@consoleLogger.warn(message)
			@fileLogger.warn(message)
  		end
  	end

  	def info(message)	
  		if @level >= 1
	  		message = add_meta_data(message)
			@logglyLogger.info(message)  		
			@consoleLogger.info(message)
			@fileLogger.info(message)
  		end
  	end


  	def debug(message)
		if @level >= 0
	  		message = add_meta_data(message)
			@logglyLogger.debug(message)  
			@consoleLogger.debug(message)
			@fileLogger.debug(message)
		end
  	end

  	def add_meta_data(message)

  		caller_infos = caller.second.split(":in")

		message_with_meta_data =  "#{caller_infos[0]} - Thread ID :  #{Thread.current.object_id.to_s}  Request ID : #{Thread.current[:request_uuid]} " + message.to_s
		
  		if message.is_a? StandardError
  			message_with_meta_data = add_stacktrace(message,message_with_meta_data)
  		end

  		message_with_meta_data
  	end	

  	def add_stacktrace(message,message_with_meta_data)
  		message = "#{message_with_meta_data} \n #{message.backtrace}";
  	end

  end
end

