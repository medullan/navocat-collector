require 'java'
require 'jdbc/postgres'

require_relative "../../../postgresql-9.3-1102.jdbc41.jar"
require_relative "postgres_connection_pool_service.rb"
require_relative "../../../javassist-3.19.0-GA.jar"
require_relative "../../../slf4j-api-1.7.10.jar"
require_relative "../../../slf4j-simple-1.7.10.jar"
require_relative "../../../HikariCP-2.3.0.jar"


java_import java.sql.DriverManager
java_import org.postgresql.util.PGobject


Jdbc::Postgres.load_driver(:require) if Jdbc::Postgres.respond_to?(:load_driver)

module Meda

  class PostgresLoggingService

	attr_accessor :dburl

  	def initialize(config)
  		DriverManager.register_driver(org.postgresql.Driver.new)
  		@dburl = config.db_url
  		@pool = Meda::PostgresConnectionPoolService.new(config)

        @postgres_thread_pool = Meda::WorkerPool.new({
          :size => config.postgres_thread_pool,
          :name => "postgres_thread_pool"
        })

        at_exit do
          @postgres_thread_pool.shutdown
        end
  	end

  	def error(message)
  		writeToDb(message);
  	end

  	def warn(message)
  		writeToDb(message);
  	end

  	def info(message)
  		writeToDb(message);
  	end

  	def debug(message)
  		writeToDb(message);
  	end

  	def writeToDb(message)
		@postgres_thread_pool.submit do 
			write(message)	
		end	
  	end

  	def write(message)
		begin
			connection = @pool.get_connection()
			preparedStatement = connection.prepareStatement("INSERT INTO logs(log) VALUES (?)")
			jsonObject = PGobject.new
			jsonObject.setType("jsonb")
			jsonObject.setValue(message)

			preparedStatement.setObject(1,jsonObject)
		    preparedStatement.executeUpdate()
		    preparedStatement.close()
			connection.close()  			
  			rescue Exception => error
   			puts "!! POSTGRES LOGGING ERROR !! -- #{error.message} -- #{error.backtrace}"
		
		end  		
  	end
  end
end



