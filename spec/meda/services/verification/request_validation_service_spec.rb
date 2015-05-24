require_relative '../../../../lib/meda/services/verification/request_verification_service.rb'
require_relative '../../../../lib/meda/services/profile/profile_service.rb'
require_relative '../../../../lib/meda/services/datastore/profile_data_store.rb'

require 'json'




describe Meda::RequestVerificationService do

  @@thread_key = "meda_rva_id"
  @@prefix = "rva-"
  @@base_json_path= 'spec/meda/services/verification'

  Meda.configuration.env = 'test'
  Meda.configuration.verification_api = {:log_size => 5, :collection_name => 'rva-test', :id_prefix => 'rva-', :thread_id_key => 'meda_rva_id'}
  features = {:verification_api=>true, :profile_store=> 'redisdb', :profile_loader=> true, :profile_service => 'onekey'}
  Meda.configuration.features.merge(features)
  puts Meda.configuration
  describe 'test uuid generation' do

    xit 'should start with prefix' do

      request_validation_service = Meda::RequestVerificationService.new()
      uuid = request_validation_service.generate_transaction_id()
      expect(uuid.to_s).to start_with(Meda.configuration.verification_api[:id_prefix])
      # Meda.configuration.verification_api.collection_name
    end

    xit 'should be saved in the thread' do
      request_validation_service = Meda::RequestVerificationService.new()
      uuid = request_validation_service.set_transaction_id()

      expect(Thread.current[Meda.configuration.verification_api[:thread_id_key]]).to equal(uuid)
    end



  end

  describe 'test storing an rva log' do

    before(:each) do

      # Meda.configuration.features ={}
      # Meda.configuration.features['profile_store'] = 'redisdb'

    end

    after(:each) do
      # features = {:profile_store=> 'redisdb', :profile_loader=> true, :profile_service => 'onekey'}
      # Meda.configuration.features = nil
    end

    xit 'should be saved in the data' do

      # test_config = Meda.configuration.deep_dup
      # test_config.features = {}

      test_id = "#{Meda.configuration.verification_api[:id_prefix]}87238723-323232332"
      profile_service= Meda::ProfileDataStore.new(Meda.configuration)

      uuid = UUIDTools::UUID.random_create.to_s
      uuid = "#{Meda.configuration.verification_api[:id_prefix]}#{uuid}"
      # result = profile_service.decode('rva')
      # profile_service.encode("rva:#{test_id}5", {:id => test_id})
      # puts result

      profile_service.encode_collection('rva', uuid, {:id => uuid})
      list = profile_service.decode_collection('rva')
      filter = profile_service.decode_collection_filter_by_key('rva', 'rva-54ffccec-be33-4125-b920-e646184313b1')
      exists = profile_service.key_in_collection?('rva', 'rva-54ffccec-be33-4125-b920-e646184313b1')
      deleted = profile_service.delete_key_within_collection('rva', 'rva-a46ddda3-38e9-4eb2-9569-4cdef8a5f883')

      puts list
      puts filter
      puts "key exists: #{exists}"
      puts "deleted?: #{deleted}"
      expect(true).to be_truthy

    end

    it 'should find json that relates to a unique collector hit' do
      request_verification_service = Meda::RequestVerificationService.new(Meda.configuration)
      page_rva_data = {:id=> 'rva-232323232', :type=> 'page', :transaction_ids => {:json => '0f1c2f70f99b11e4ae05003ee1fffe52'}}
      json_list = request_verification_service.get_all_json_data(@@base_json_path)
      source_type= 'json'
      match = request_verification_service.get_related_json_data(json_list, page_rva_data, source_type)
      expect(match['id']).to eq(page_rva_data[:transaction_ids][source_type.to_sym])
    end

    it 'should not any find json that relates to a unique collector hit' do
      request_verification_service = Meda::RequestVerificationService.new(Meda.configuration)
      page_rva_data = {:id=> 'rva-232323232', :type=> 'page', :transaction_ids => {:json => '-test-0f1c2f70f99b11e4ae05003ee1fffe52'}}
      json_list = request_verification_service.get_all_json_data(@@base_json_path)
      source_type= 'json'
      match = request_verification_service.get_related_json_data(json_list, page_rva_data, source_type)
      expect(match).to eq(nil)
    end

    it 'should get all  json objects within each file within the meta data folder' do
      request_verification_service = Meda::RequestVerificationService.new(Meda.configuration)
      json_list = request_verification_service.get_all_json_data(@@base_json_path)
      expect(json_list.size).to be(4)
    end

    it 'should parse single json file into array of hash objects' do
      request_verification_service = Meda::RequestVerificationService.new(Meda.configuration)
      file_path = "#{@@base_json_path}/test/pageviews/2015-05-06/2015-05-06-16-00-00-28917570f42b11e49336003ee1fffe52.json"
      json_list = request_verification_service.parse_meda_json(file_path)
      expect(json_list.size).to be(2)
    end

    it 'should get a list of all json files within the directory' do
      request_verification_service = Meda::RequestVerificationService.new(Meda.configuration)
      json_files = request_verification_service.get_json_filepaths(@@base_json_path)
      expect(json_files.size).to be(3)
    end

    it 'should add a ref to the log for a json datasource' do
      json_data = {:id=>'7665'}
      page_rva_data = {:id=> 'rva-232323232', :type=> 'page'}
      request_verification_service = Meda::RequestVerificationService.new(Meda.configuration)
      rva_data = request_verification_service.add_data_source('transaction_ids',page_rva_data, 'json', json_data[:id])
      expect(rva_data[:transaction_ids][:json]).to eq(json_data[:id])
    end

    # it 'should be saved in the data' do
    #   test_config = Meda.configuration.clone
    #   test_config.features = {}
    #   features = {:profile_store=> 'redisdb', :profile_loader=> true, :profile_service => 'onekey'}
    #   test_config.features.merge(features)
    #   test_id = 'rva-87238723-323232332'
    #   profile_service= Meda::ProfileDataStore.new(test_config)
    #   profile_service.encode(test_id, {:id => test_id})
    #
    #   # ret_hash = profile_service.decode(test_id)
    #   # expect(ret_hash['id']).to eq(test_id)
    #   expect(true).to be_truthy
    # end


    # it 'should merge and build a RVA log' do
    #   json_data = {:id=> '28917570f42b11e49336003ee1fffe52'}
    #   ga_data = {:id => '28917570f42b11e49336003ee1fffe52'}
    #   profile_data = [{:id => '3e23e223e23323323233'}, {:id => 'tguyg766t8y7877t89y98'}]
    #   page_rva_data = {:id=> 'rva-232323232', :type=> 'page', :transaction_id => {:json => '28917570f42b11e49336003ee1fffe52'}}
    #   json_folder_prefix = {:page => 'pageviews', :track => 'events'}
    #
    # end

  end

  end
