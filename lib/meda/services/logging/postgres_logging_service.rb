require 'pg/em'





  # asynchronous


module Meda

  class PostgredLoggingService


  	def info(message)
	  pg = PG::EM::Client.new dbname: 'collector-logs'

	  # asynchronous
	  EM.run do
	    Fiber.new do
	      pg.query("INSERT INTO logs(log) VALUES (#{message})" 
	    end  
	  EM.stop
	    end.resume
  	  end
  	end

  end
end

