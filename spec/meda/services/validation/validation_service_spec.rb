require 'logger'
require_relative '../../../../lib/meda/services/validation/validation_service.rb'

describe 'Validation service' do

  before(:each) do
    @validation_service = Meda::ValidationService.new()
    @client_id = "12345"
  end

  describe 'valid_request?' do

    before(:each) do
      @dataset = { :dataset => "123456" }
    end

    context 'with valid client_id and dataset' do
      it 'should return true' do
        expect(@validation_service.valid_request?(@client_id, @dataset)).to be_truthy
      end
    end

    context 'with nil dataset'  do
      it 'should return false' do
        @dataset[:dataset] = nil
        expect(@validation_service.valid_request?(@client_id,@dataset)).to be_falsey
      end
    end

    context 'with empty dataset' do
      it "should return false" do
        @dataset[:dataset] = ''
        expect(@validation_service.valid_hit_request?(@client_id, @dataset)).to be_falsey
      end
    end

    context 'with nil client_id' do
      it "should return false" do
        @client_id = nil
        expect(@validation_service.valid_hit_request?(@client_id, @dataset)).to be_falsey
      end
    end

    context 'with empty client_id' do
      it "should return false" do
        @client_id = ''
        expect(@validation_service.valid_hit_request?(@client_id, @dataset)).to be_falsey
      end
    end

  end

  describe 'valid_hit_request?' do

    before(:each) do
      @request_hash = {:path => "/test/path"}
    end

    context 'with valid path' do
      it "should return true" do
        expect(@validation_service.valid_hit_request?(@client_id, @request_hash))
      end
    end

    context 'with nil path' do
      it 'should return false' do
        @request_hash[:path] = nil
        expect(@validation_service.valid_hit_request?(@client_id, @request_hash)).to be_falsey
      end
    end

    context 'with nil path' do
      it 'should return false' do
        @request_hash[:path] = ''
        expect(@validation_service.valid_hit_request?(@client_id, @request_hash)).to be_falsey
      end
    end

  end

end