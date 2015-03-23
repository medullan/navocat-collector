require 'logger'
require_relative '../../../../lib/meda/services/validation/validation_service.rb'

describe Meda::ValidationService do

  let(:client_id) { "12345" }

  describe '.valid_request?' do

    let(:dataset) { { :dataset => "123456" } }
    context 'with valid client_id and dataset' do
      it 'should return true' do
        expect(subject.valid_request?(client_id, dataset)).to eql(true)
      end
    end

    context 'with nil dataset'  do
      it 'should return false' do
        dataset[:dataset] = nil
        expect(subject.valid_request?(client_id,dataset)).to eql(false)
      end
    end

    context 'with empty dataset' do
      it "should return false" do
        dataset[:dataset] = ''
        expect(subject.valid_hit_request?(client_id, dataset)).to eql(false)
      end
    end

    context 'with nil client_id' do
      it "should return false" do
        @client_id = nil
        expect(subject.valid_hit_request?(client_id, dataset)).to eql(false)
      end
    end

    context 'with empty client_id' do
      it "should return false" do
        client_id = ''
        expect(subject.valid_hit_request?(client_id, dataset)).to eql(false)
      end
    end

  end

  describe '.valid_hit_request?' do

    let(:request_hash) { {:dataset => "123456", :path => "/test/path"} }

    context 'with valid path' do
      it "should return true" do
        expect(subject.valid_hit_request?(client_id, request_hash)).to eql(true)
      end
    end

    context 'with nil path' do
      it 'should return false' do
        request_hash[:path] = nil
        expect(subject.valid_hit_request?(client_id, request_hash)).to eql(false)
      end
    end

    context 'with nil path' do
      it 'should return false' do
        request_hash[:path] = ''
        expect(subject.valid_hit_request?(client_id, request_hash)).to eql(false)
      end
    end

    context 'when valid_request? returns false' do
      it "should return false as well" do
        allow(subject).to receive(:valid_request?).and_return(false)
        expect(subject.valid_hit_request?(client_id, request_hash)).to eql(false)
      end
    end

    context 'when valid_hit_request? is called' do
      it "should call valid_request?" do
        expect(subject).to receive(:valid_request?).with(client_id, request_hash)
        subject.valid_hit_request?(client_id, request_hash)
      end
    end
  end

  describe '.valid_profile_request?' do
    let(:request_hash) { {:profile_id => "12345665432",:dataset => "123456", :path => "/test/path"} }

    context 'when profile_id is present' do
      it "should return true" do
        allow(subject).to receive(:valid_request?).and_return(true)
        expect(subject.valid_profile_request?(client_id, request_hash)).to eql(true)
      end
    end

    context 'when profile_id is not present' do
      it "should should return false" do
        allow(subject).to receive(:valid_request?).and_return(true)
        request_hash[:profile_id] = ''
        expect(subject.valid_profile_request?(client_id, request_hash)).to eql(false)
      end
    end

    context 'when profile_id is valid' do
      it "should call valid_request?" do
        expect(subject).to receive(:valid_request?).with(client_id, request_hash)
        subject.valid_profile_request?(client_id, request_hash)
      end
    end
  end

end