#require 'logglier' 
require 'logger'

module Meda

#TODO use fowardable?
  class LoggingService

	attr_accessor :level, :log, :nativelogger
	
   	def initialize(log_path)
   #   	@log = Logglier.new("https://logs-01.loggly.com/inputs/d3edcdea-6c63-446a-a60b-4cb7db999d55/tag/ruby/", :format => :json) 
      	
      	@nativeLogger = Logger.new(Meda.configuration.log_path)
      #	@nativelogger.level = Meda.configuration.log_level || Logger::INFO
    end

  	def info(message)	
  	#	message = add_meta_data(message)
	#	@log.info(message)  		
		@nativeLogger.info(message)
  	end


  	def error(message)
  	#	message = add_meta_data(message)
	#	@log.error(message)  
		@nativeLogger.error(message)
  	end

  	def debug(message)
  #		message = add_meta_data(message)
	#	@log.debug(message)  
		@nativeLogger.debug(message)
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

