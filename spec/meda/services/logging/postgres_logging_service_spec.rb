require_relative '../../../../lib/meda/services/logging/postgres_logging_service'


describe Meda::PostgresLoggingService do


  describe 'postgres logging service' do
    it 'logs using info calls' do

      	json_message = '{"message2":"love"}'

      	postgresLoggingService = Meda::PostgresLoggingService.new(Meda.configuration)	

		postgresLoggingService.info(json_message)
    end
  end


end
