require_relative '../../../../lib/meda/services/verification/request_verification_service.rb'
require_relative '../../../../lib/meda/services/datastore/redisdb/redisdb_store.rb'

require 'json'




describe Meda::RequestVerificationService do

  @@thread_key = "meda_rva_id"
  @@prefix = "rva-"
  @@base_json_path= 'spec/meda/services/verification'

  Meda.configuration.env = 'test'
  Meda.configuration.verification_api = {'limit' => 5, 'collection_name' => 'rva-test', 'id_prefix' => 'rva-', 'thread_id_key' => 'meda_rva_id'}
  features = {:verification_api=>true, :profile_store=> 'redisdb', :profile_loader=> true, :profile_service => 'onekey'}
  Meda.configuration.features.merge(features)
  LOG_KEY_IDS = { :cid => 'cid', :rid => 'rid', :pid => 'pid', :sort => 'sort' }
  @@request_verification_service = Meda::RequestVerificationService.new(Meda.configuration)

  describe 'test storing an rva log' do
    it 'should find json that relates to a unique collector hit' do
      request_verification_service = Meda::RequestVerificationService.new(Meda.configuration)
      page_rva_data = {'id'=> 'rva-232323232', 'type'=> 'page', 'transaction_ids' => {'json' => '0f1c2f70f99b11e4ae05003ee1fffe52'}}
      json_list = request_verification_service.get_all_json_data(@@base_json_path)
      source_type= 'json'
      match = request_verification_service.get_related_json_data(json_list, page_rva_data, source_type)
      expect(match['id']).to eq(page_rva_data['transaction_ids'][source_type])
    end

    it 'should not any find json that relates to a unique collector hit' do
      request_verification_service = Meda::RequestVerificationService.new(Meda.configuration)
      page_rva_data = {'id'=> 'rva-232323232', 'type'=> 'page', 'transaction_ids' => {'json' => '-test-0f1c2f70f99b11e4ae05003ee1fffe52'}}
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
      json_data = {'id'=>'7665'}
      page_rva_data = {'id'=> 'rva-232323232', 'type'=> 'page'}
      request_verification_service = Meda::RequestVerificationService.new(Meda.configuration)
      rva_data = request_verification_service.add_data_source('transaction_ids',page_rva_data, 'json', json_data['id'])
      expect(rva_data['transaction_ids']['json']).to eq(json_data['id'])
    end

    it 'should create a log key when values passed' do
      delim = '|'
      collection = 'rva'
      profile_id = '123'
      client_id = '456'
      rva_id = 'rva-789'
      sort_key = Time.now.to_i.to_s
      key_template = "#{collection}#{delim}#{LOG_KEY_IDS[:pid]}(#{profile_id})#{delim}#{LOG_KEY_IDS[:cid]}(#{client_id})#{delim}#{LOG_KEY_IDS[:rid]}(#{rva_id})#{delim}#{LOG_KEY_IDS[:sort]}(#{sort_key})#{delim}"
      key = @@request_verification_service.create_log_key(collection, profile_id, client_id, rva_id, sort_key)
      puts key
      expect(key).to eq(key_template)
    end

    it 'should create a log key when nil or empty values passed' do
      delim = '|'
      collection = 'rva'
      profile_id = nil
      client_id = ''
      rva_id = 'rva-789'
      sort_key = Time.now.to_i.to_s
      key_template = "#{collection}#{delim}#{LOG_KEY_IDS[:pid]}(none)#{delim}#{LOG_KEY_IDS[:cid]}(none)#{delim}#{LOG_KEY_IDS[:rid]}(#{rva_id})#{delim}#{LOG_KEY_IDS[:sort]}(#{sort_key})#{delim}"
      key = @@request_verification_service.create_log_key(collection, profile_id, client_id, rva_id, sort_key)
      puts key
      expect(key).to eq(key_template)
    end

    it 'should get substring value from log key' do
      key = 'rva|pid(none)|cid(none)|rid(rva-789)|sort(1433985859)|'
      key_id = 'rid'
      value = @@request_verification_service.get_value_from_log_key(key, key_id)
      expect(value).to eq('rva-789')
    end

    it 'should get hash values from log key' do
      key = 'rva|pid(none)|cid(none)|rid(rva-789)|sort(1433985859)|'
      expected = {"rid"=>"rva-789", "pid"=>"none", "cid"=>"none", "sort"=>"1433985859"}
      hash = @@request_verification_service.get_hash_from_log_key(key)
      expect(hash).to eq(expected)
    end


    it 'should sort values in asc order' do
      unsorted = [
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(4)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(3)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(5)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(2)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(1)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(6)|'
      ]

      sorted = [
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(1)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(2)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(3)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(4)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(5)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(6)|'
      ]

      values = @@request_verification_service.sort_log_keys(unsorted)
      expect(values).to eq(sorted)
    end

    it 'should sort values in desc order' do
      unsorted = [
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(4)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(3)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(5)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(2)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(1)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(6)|'
      ]

      sorted = [
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(6)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(5)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(4)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(3)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(2)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(1)|'
      ]

      values = @@request_verification_service.sort_log_keys(unsorted, false)
      expect(values).to eq(sorted)
    end

    it 'should get values that are over the limit' do

      org_list = [
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(1)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(2)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(3)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(4)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(5)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(6)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(7)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(8)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(9)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(10)|'
      ]

      trunc_list = [
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(1)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(2)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(3)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(4)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(5)|'
       ]

      values = @@request_verification_service.get_ids_for_logs_outside_limit(org_list)
      expect(values).to eq(trunc_list)
    end

    it 'should return empty array if log count is within limit' do

      org_list = [
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(1)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(2)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(3)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(4)|',
          'rva|pid(none)|cid(none)|rid(rva-789)|sort(5)|'
      ]

      trunc_list = []

      values = @@request_verification_service.get_ids_for_logs_outside_limit(org_list)
      expect(values).to eq(trunc_list)
    end

  end

end
