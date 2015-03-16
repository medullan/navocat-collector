=begin
require 'logger'
require 'meda/services/logging/logging_meta_data_service'
require_relative '../../../../lib/meda/services/ga_debug/ga_debug_service'
require 'meda'
require_relative '../../../../lib/meda/services/filter/request_url_filter_service'

describe Meda::GAHitDebugService do

  describe '.debug_ga_response' do

    config = {}
    config["config"] = Meda.configuration
    config["config"].hash_salt = "foo"
    before(:each) do
      @mock_logging_meta_data_service = double(Meda::LoggingMetaDataService.new(config), :add_to_mdc => "", :add_to_mdc_hash => "")
      @mock_logging_meta_data_service.stub!(:add_to_mdc).and_return("test")
      @mock_logging_meta_data_service.stub!(:add_to_mdc_hash).and_return("test")
    end

    let(:ga_response) { { :validity => true, :parser_message => 'foo', :params_sent_to_ga => { 'v' => 1} } }

    context 'when ga_response is valid' do
      it 'should call logging_meta_data_service.add_to_mdc' do
        expect(@mock_logging_meta_data_service).to receive(:add_to_mdc)
        expect(@mock_logging_meta_data_service).to receive(:add_to_mdc_hash)
        subject.debug_ga_response(ga_response)
      end

      it 'should call logging_meta_data_service.add_to_mdc_hash'
    end

    context 'when ga_response is not valid' do
      it 'should throw an exception'

      it 'should not call logging_meta_data_service'
    end
  end
end
=end