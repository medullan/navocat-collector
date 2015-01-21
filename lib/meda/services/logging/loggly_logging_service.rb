require "httparty"

module Meda

  class LogglyLoggingService

  	def initialize(config)
        @@loggly_url = config.loggly_url
        @loggly_api_pool = Meda::WorkerPool.new({
          :size => config.loggly_pool,
          :name => "loggly_pool"
        })

        at_exit do
          @loggly_api_pool.shutdown
        end
  	end

  	def error(message)
  		writeToAPI(message);
  	end

  	def warn(message)
  		writeToAPI(message);
  	end

  	def info(message)
  		writeToAPI(message);
  	end

  	def debug(message)
  		writeToAPI(message);
  	end

  	def writeToAPI(message)
		@loggly_api_pool.submit do 
			write(message)	
		end	
  	end

  	def write(message)
		begin
			HTTParty.post(@@loggly_url,
				:body => message,
				:headers => { 'Content-Type' => 'application/json' })
		rescue StandardError => error
			puts "!! LOGGLY LOGGING ERROR !! -- #{error.message} -- #{error.backtrace}"
		end  		
  	end
  end
end



