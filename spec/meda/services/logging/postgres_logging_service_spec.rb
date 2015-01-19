require_relative '../../../../lib/meda/services/logging/postgres_logging_service'


describe Meda::PostgresLoggingService do


  describe 'postgres logging service' do
    it 'logs using info calls' do

      json_message = %Q('{"message2":"love #{Time.new().inspect}"}')

 

      postgresLoggingService = Meda::PostgresLoggingService.new(Meda.configuration)

      
		#t1=Thread.new{
			postgresLoggingService.info(json_message)
		#}

    end
  end


end
