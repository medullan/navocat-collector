require 'java'
require_relative '../../../h2-1.3.176.jar'

java_import org.h2.jdbcx.JdbcConnectionPool;



module Meda

  class H2ConnectionPoolService

    def initialize(db_conn_url)
        @cp = JdbcConnectionPool.create(db_conn_url, "sa", "");

        at_exit do
          @cp.dispose()
        end
    end

    def get_connection()
      return @cp.getConnection()
    end

  end
end