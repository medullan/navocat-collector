require_relative 'spec_helper'
require_relative '../../lib/meda/services/profile/look_up/profile_with_look_up_service.rb'
require 'tempfile'


describe Meda::ProfileWithLookUpService do
  subject do
   
#    tmpfile = Tempfile.new("testdb_#{rand(10000000)}")
    config = {}
    config["config"] = Meda.configuration
    config["name"] = "testdb_#{rand(10000000)}"
    Meda::ProfileWithLookUpService.new(config)
  end

  describe '#create_profile' do
    it 'creates a profile record with lookups' do
      info = {'member_id' => '1234567890', 'contract_id' => '0987654321'}
      profile_id = subject.create_profile(info)['id']
      expect(subject.profile_db.key?(subject.profile_key(profile_id))).to be_truthy
      expect(subject.profile_db.key?(subject.key_hashed_profile_lookup('member_id', '1234567890'))).to be_truthy
      expect(subject.profile_db.key?(subject.key_hashed_profile_lookup('contract_id', '0987654321'))).to be_truthy
    end
  end

  describe '#alias_profile' do
    it 'adds additional identifying info and lookups to profile' do
      info = {'member_id' => '1234567890', 'contract_id' => '0987654321'}
      profile_id = subject.create_profile(info)['id']
      subject.alias_profile(profile_id, {'employee_id' => '1234'})
      expect(subject.profile_db.key?(subject.key_hashed_profile_lookup('employee_id', '1234'))).to be_truthy
    end
  end

  describe '#find_or_create_profile' do
    context 'with a new profile' do
      it 'creates a new profile' do
        info = {'member_id' => '1234567890', 'contract_id' => '0987654321'}
        profile_id = subject.find_or_create_profile(info)['id']
        expect(subject.profile_db.key?(subject.profile_key(profile_id))).to be_truthy
      end
    end

    context 'wth an existing profile' do
      it 'returns the existing profile' do
        info = {'member_id' => '1234567890', 'contract_id' => '0987654321'}
        profile_id = subject.create_profile(info)['id']
        response = subject.find_or_create_profile(info)
        expect(response).to eq({'id' => profile_id})
      end
    end
  end

  describe '#get_profile_by_id' do
    it 'returns the profile info for the given id' do
      info = {'member_id' => '1234567890', 'contract_id' => '0987654321'}
      profile_id = subject.create_profile(info)['id']
      response = subject.get_profile_by_id(profile_id)
      expect(response).to eq({'id' => profile_id})
    end
  end

  describe '#set_profile' do
    it 'sets the profile info for the given id' do
      info = {'member_id' => '1234567890', 'contract_id' => '0987654321'}
      profile_id = subject.create_profile(info)['id']
      subject.set_profile(profile_id, {'state' => 'Maine'})
      response = subject.get_profile_by_id(profile_id)
      expect(response).to eq({'id' => profile_id, 'state' => 'Maine'})
    end
  end

  describe '#lookup_profile' do
    it 'returns the profile id for the given info' do
      info = {'member_id' => '1234567890', 'contract_id' => '0987654321'}
      profile_id = subject.create_profile(info)['id']
      response = subject.lookup_profile(info)
      expect(response).to eq(profile_id)
    end
  end
end
