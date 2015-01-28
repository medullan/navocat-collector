require 'java'
require_relative '../../../h2-1.3.176.jar'
#require_relative "../../../HikariCP-2.3.1.jar"
require_relative "../../../HikariCP-java6-2.3.1.jar"

#java_import org.h2.jdbcx.JdbcConnectionPool;
java_import com.zaxxer.hikari.HikariConfig
java_import com.zaxxer.hikari.HikariDataSource


module Meda

  class H2ConnectionPoolService

    def initialize(db_conn_url)
        #@cp = JdbcConnectionPool.create(db_conn_url, "sa", "");
        DriverManager.register_driver(org.h2.Driver.new)
        config = HikariConfig.new
        config.setMaximumPoolSize(10)
        config.setMaxLifetime(3600000)  #one hour
        config.setJdbcUrl(db_conn_url);
        config.setDriverClassName("org.h2.jdbcx.JdbcDataSource")
        config.setUsername("sa");
        config.setPassword("");
        config.setLeakDetectionThreshold(10000)
        config.addDataSourceProperty("cachePrepStmts", "true");
        config.addDataSourceProperty("prepStmtCacheSize", "250");
        config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");
        config.addDataSourceProperty("useServerPrepStmts", "true");



        @cp = HikariDataSource.new(config);
    end

    def get_connection()
      return @cp.getConnection()
    end

    # def set_login_timeout(timeout)
    #   @cp.setLoginTimeout(timeout)
    # end
    
    # def set_max_connections(max)
    #   @cp.setMaxConnections(max)
    # end
  end
end