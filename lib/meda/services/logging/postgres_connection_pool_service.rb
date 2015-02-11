require 'java'


require_relative "../../../javassist-3.19.0-GA.jar"
require_relative "../../../slf4j-api-1.7.10.jar"
require_relative "../../../slf4j-simple-1.7.10.jar"
require_relative "../../../HikariCP-2.3.0.jar"

java_import com.zaxxer.hikari.HikariConfig
java_import com.zaxxer.hikari.HikariDataSource
java_import org.postgresql.jdbc4.Jdbc4Connection



module Meda

  class PostgresConnectionPoolService

  	def initialize(config)
  		puts "config #{config.postgres_logger}"
 		hk_config = HikariConfig.new  
        hk_config.setMaximumPoolSize(20)
   
        hk_config.setDataSourceClassName("org.postgresql.ds.PGSimpleDataSource")
        hk_config.addDataSourceProperty("user",config.postgres_logger["username"])
        hk_config.addDataSourceProperty("password",config.postgres_logger["password"])
        hk_config.addDataSourceProperty("serverName",config.postgres_logger["server"])
		    hk_config.addDataSourceProperty("portNumber",config.postgres_logger["port"])
		    hk_config.addDataSourceProperty("databaseName",config.postgres_logger["database"])
        @ds = HikariDataSource.new(hk_config)
  	end

  	 

  	def get_connection()
  		return @ds.getConnection()
  	end
  end
end



