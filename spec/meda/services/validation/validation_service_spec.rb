require 'logger'
require_relative '../../../../lib/meda/services/validation/validation_service.rb'

describe 'Validation service' do

  before(:each) do
    @validation_service = Meda::ValidationService.new()
  end

  describe 'valid_request?' do

    before(:each) do
      @dataset = { :dataset => "123456" }
    end

    it 'should ensure dataset exist' do
      expect(@validation_service.valid_request?(@dataset)).to be_truthy
    end

    it 'should log error message when dataset is missing and return false' do
      @dataset[:dataset] = nil
      expect(@validation_service.valid_request?(@dataset)).to be_falsey
    end

  end

  describe 'valid_hit_request?' do

    before(:each) do
      @request_hash = {:dataset => "123456", :client_id => "123456", :path => "/test/path"}
    end

    it 'should ensure valid_hit_request? is called with request params and is valid' do
      expect(@validation_service.valid_hit_request?(@request_hash)).to be_truthy
    end

    it 'should ensure valid_hit_request? is called with a valid client_id' do
      @request_hash[:client_id] = nil
      expect(@validation_service.valid_hit_request?(@request_hash)).to be_falsey
    end

    it 'should ensure valid_hit_request? is called with a valid path' do
      @request_hash[:path] = nil
      expect(@validation_service.valid_hit_request?(@request_hash)).to be_falsey
    end
  end

end