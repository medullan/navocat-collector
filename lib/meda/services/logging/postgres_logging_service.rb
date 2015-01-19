require 'java'
require 'jdbc/postgres'
require 'eventmachine'
require_relative "../../../postgresql-9.3-1102.jdbc41.jar"

java_import java.sql.DriverManager
java_import org.postgresql.util.PGobject

Jdbc::Postgres.load_driver(:require) if Jdbc::Postgres.respond_to?(:load_driver)

module Meda

  class PostgresLoggingService

	attr_accessor :dburl

  	def initialize(config)
  		DriverManager.register_driver(org.postgresql.Driver.new)
  		@@dburl = config.db_url
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

		begin

			connection = DriverManager.get_connection(@@dburl)
			st = connection.prepareStatement("INSERT INTO logs(log) VALUES (?)");

			jsonObject = PGobject.new
			jsonObject.setType("jsonb");
			jsonObject.setValue(message);

			st.setObject(1,jsonObject);
		    st.executeUpdate()
		    st.close()
			connection.close()
  			
  			rescue StandardError => error
   			puts "!! LOGGING ERROR !! -- #{error.message}"
		
		end

  	end
  end
end



