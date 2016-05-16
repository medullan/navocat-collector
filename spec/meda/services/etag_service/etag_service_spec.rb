require_relative '../../../../lib/meda/services/etag/etag_service'

describe Meda::EtagService do

  describe '.string_to_hash' do
    context 'when the etag string is valid' do
      it 'should return a valid hash' do
        expect(subject.string_to_hash("client_id=123;profile_id=321;")["client_id"]).to eql("123")
        expect(subject.string_to_hash("client_id=123;profile_id=321;")["profile_id"]).to eql("321")
      end
    end
  end

  describe '.hash_to_string' do
    context 'when the etag is valid' do
      it 'should return a valid semi colon delimited etag string' do
        etag = Hash.new
        etag["client_id"] = "123"
        etag["profile_id"] = "321"
        expect(subject.hash_to_string(etag)).to eql("client_id=123;profile_id=321;")
      end
    end
  end
end