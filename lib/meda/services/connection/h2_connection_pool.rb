# require 'java'
# require 'meda'
# require 'jdbc/h2'
# require 'logger'


# require_relative '../../../h2-1.3.176.jar'
# require_relative "../../../javassist-3.19.0-GA.jar"
# require_relative "../../../slf4j-api-1.7.10.jar"
# require_relative "../../../slf4j-simple-1.7.10.jar"
# require_relative "../../../HikariCP-2.3.0.jar"

# java_import com.zaxxer.hikari.HikariConfig
# java_import com.zaxxer.hikari.HikariDataSource
# java_import org.h2.jdbcx.JdbcDataSource

# Jdbc::H2.load_driver(:require) if Jdbc::H2.respond_to?(:load_driver)

module Meda

  class H2ConnectionPoolService

    # def initialize()
   #    begin
   #      #puts "config #{config.postgres_logger}"
   #      DriverManager.register_driver(org.h2.Driver.new)
   #      hk_config = HikariConfig.new  
   #      hk_config.setMaximumPoolSize(20)
     
   #      hk_config.setDataSourceClassName("org.h2.jdbcx.JdbcDataSource")
   #      hk_config.addDataSourceProperty("user","sa")
   #      hk_config.addDataSourceProperty("password","")
   #      hk_config.addDataSourceProperty("url", "jdbc:h2:tcp://localhost/~/test")
   #      @ds = HikariDataSource.new(hk_config)
   #    rescue Exception => error
   #      puts "!! ERROR INITILIZING H2ConnectionPoolService !! -- #{error.message} -- #{error.backtrace}"
   #    end
    # end

    # def get_connection()
    #   return @ds.getConnection()
    # end
  end
end