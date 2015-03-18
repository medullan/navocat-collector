require 'logger'
require 'meda'
require 'meda/services/logging/logging_meta_data_service'
require_relative '../../../../lib/meda/services/ga_debug/ga_debug_service'

describe Meda::GAHitDebugService do

  let(:ga_response_json) { {'hit_parsing_result' =>
                                [{'valid' => true, 'parser_message' =>
                                     [{'message_type' => "INFO", 'description' => "foo"}],
                                  'hit' => "foo bar"}]} }

  let(:debug_ga_response) { {:ga_response_code => "200",
                             :ga_response_json => ga_response_json,
                             :params_sent_to_ga => {'v' => 1, 'tid' => 'foo', 't' => 'pageview'}} }

  let(:ga_response) { {:validity => true,
                       :parser_message => "foo bar"} }

  describe '.debug_ga_info' do

    before(:each) do
      allow(subject).to receive(:parse_ga_response).and_return("{}")
      allow(subject).to receive(:construct_ga_debug_object).and_return(ga_response)
    end

    context 'when last_debug_ga_response contain a non 200 http request' do
      before(:each) do
        debug_ga_response[:ga_response_code] = "302"
      end

      it "should not call parse_ga_response" do
        subject.debug_ga_info(debug_ga_response)
        expect(subject).to have_received(:parse_ga_response).exactly(0).times
      end

      it "should not call construct_ga_debug_object" do
        subject.debug_ga_info(debug_ga_response)
        expect(subject).to have_received(:construct_ga_debug_object).exactly(0).times
      end
    end

    context 'when last_debug_ga_response contains a 200 http request' do
      it 'should call parse_ga_response once' do
        subject.debug_ga_info(debug_ga_response)
        expect(subject).to have_received(:parse_ga_response).once
      end

      it "should call construct_ga_debug_object once" do
        subject.debug_ga_info(debug_ga_response)
        expect(subject).to have_received(:construct_ga_debug_object).once
      end
    end
  end

  describe '.construct_ga_debug_object' do

    context 'when param is nil' do
      it "should return hash with nil items" do
        result = subject.construct_ga_debug_object(nil)
        expect(result[:validity]).to be_nil
        expect(result[:parser_message]).to be_nil
      end
    end

    context 'when param is valid' do
      it "should return with hash containing validity to be true and non empty parser_message string" do
        result = subject.construct_ga_debug_object(ga_response_json)
        expect(result[:validity]).to eql(true)
        expect(result[:parser_message]).to eql("valid--true--parser_message--{\"message_type\"=>\"INFO\", \"description\"=>\"foo\"}--hit--foo bar")
      end
    end
  end

  describe '.validate_json_array' do
    context 'when json_array is nil' do
      it "should return false" do
        expect(subject.validate_json_array(nil)).to eql(false)
      end
    end

    context 'when json_array[\'hit_parsing_result\'] is nil' do
      it "should return false" do
        json_array = { 'hit_parsing_result' => nil }
        expect(subject.validate_json_array(json_array)).to eql(false)
      end
    end

    context 'when json_array[\'hit_parsing_result\'][0] is nil' do
      it "should return false" do
        json_array = { 'hit_parsing_result' => [nil] }
        expect(subject.validate_json_array(json_array)).to eql(false)
      end
    end

    context 'when json_array[\'hit_parsing_result\'][0] has value' do
      it "should return true" do
        json_array = { 'hit_parsing_result' => ["foo"] }
        expect(subject.validate_json_array(json_array)).to eql(true)
      end
    end
  end

  describe '.parse_ga_response' do
    context 'when ga_response_json is not blank' do
      it "should call JSON.parse" do
        allow(JSON).to receive(:parse).and_return("{}")
        subject.parse_ga_response("{}")
        expect(JSON).to have_received(:parse).with("{}").once
      end
    end

    context 'when ga_response_json is nil' do
      it "should return nil" do
        expect(subject.parse_ga_response(nil)).to be_nil
      end
    end
  end
end