require "logging"
require 'mail'
require 'json'
require 'socket'

module Meda

  class EmailLoggingService

  	def initialize(config)
  		@log =	Logging.logger['email']

       	appender = Logging.appenders.email( 'email',
           :from       => config.logs["error_email_from_account"],
           :to         => config.logs["error_email_to_account"],
           :subject    => "Collector Error in #{Socket.gethostname}",  
           :address    => "smtp.gmail.com",
           :port       => 587,
           :domain     => "gmail.com",
           :user_name  => config.logs["error_email_from_account"],
           :password   => config.logs["error_email_from_account_password"],
           :authentication => :login,
           :enable_starttls_auto => true,
     	     :auto_flushing => 10,     # send an email after x messages have been buffered
           :flush_period  => 5,     # send an email after x minutes
           :level         => :error # only process log events that are "error" or "fatal"
		)

       	@log.add_appenders('email')
  	end

  	def error(message)
		writeToEmail(message)
  	end

  	def warn(message)

  	end

  	def info(message)

  	end

  	def debug(message)

  	end

  	def writeToEmail(message)
		begin
	  		messageJson = JSON.parse(message)
			messageToEmail = "#{messageJson['request_uuid']} occurred at #{messageJson['timestamp']}"	
			@log.error(messageToEmail)
		rescue Exception => error
   			puts "!! EMAIL LOGGING ERROR !! -- #{error.message} -- #{error.backtrace}"		
		end  
  	end

  end
end



