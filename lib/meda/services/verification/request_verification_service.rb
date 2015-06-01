require_relative '../profile/profile_service.rb'
require_relative '../datastore/redisdb/redisdb_store.rb'
require 'uuidtools'
require 'logger'
require 'meda'
require 'json'

module Meda

  #RequestVerificationService used for the Request Verification API (RVA)
  class RequestVerificationService


    DATA_OUTPUT_PROP = 'outputs'
    TRANS_IDS_PROP = 'transaction_ids'
    FEATURE_NAME = 'verification_api'

    def initialize(config)
      @config=config
      @@log_data_store = Meda::RedisDbStore.new(config)
    end


    ### public ###

    def start_rva_log (type, data, request, cookies)
      if Meda.features.is_enabled(FEATURE_NAME, false)
        rva_id = set_rva_id()
        profile_id = data.key?(:profile_id) ? data[:profile_id] : cookies['_meda_profile_id']
        client_id = cookies['__collector_client_id']
        input = data.key?(:request_input) ? data[:request_input] : nil

        if profile_id == nil
          profile_id =  input.key?(:profile_id) ? input[:profile_id] : profile_id
        end

        end_point_type = data.key?(:end_point_type) ? data[:end_point_type] : nil
        rva_data = {
            :id => rva_id,
            :profile_id => profile_id, :client_id => client_id,
            :type => type,
            :http => {
                :start_time=> data[:start_time].to_s, :end_time=> nil,:url => request.url,
                :method => request.request_method, :request_input => input, :response=>nil, :end_point_type =>end_point_type
            }
        }
        @@log_data_store.encode_collection(@config.verification_api['collection_name'], rva_id, rva_data )
      end
    end

    def end_rva_log (response=nil)
      if Meda.features.is_enabled(FEATURE_NAME, false)
        rva_id = get_rva_id()
        if rva_id != nil
          rva_data = @@log_data_store.decode_collection_filter_by_key(@config.verification_api['collection_name'], rva_id )
          if rva_data != nil
            rva_data[:http][:end_time] = Time.now.to_s
            rva_data[:http][:response] = response
            @@log_data_store.encode_collection(@config.verification_api['collection_name'], rva_id, rva_data )
          end
        end

      end
    end

    def add_json_ref(ref)
      rva_id = get_rva_id()
      rva_data =  @@log_data_store.decode_collection_filter_by_key( @config.verification_api['collection_name'], rva_id)
      data = add_data_source(TRANS_IDS_PROP,
                             rva_data,
                             'json',
                             ref)
      @@log_data_store.encode_collection(@config.verification_api['collection_name'], rva_id, data )
      return data
    end

    def add_ga_data(ref)

      rva_id = get_rva_id()
      rva_data =  @@log_data_store.decode_collection_filter_by_key( @config.verification_api['collection_name'], rva_id)
      data = add_data_source(DATA_OUTPUT_PROP,
                             rva_data,
                             'ga',
                             ref)
      @@log_data_store.encode_collection(@config.verification_api['collection_name'], rva_id, data )
      return data
    end

    def get_rva_id()
      id = nil
      if Meda.features.is_enabled(FEATURE_NAME, false)
        id =   Thread.current.thread_variable_get(@config.verification_api['thread_id_key'])
      end
      return id
    end

    def set_rva_id(id = nil)
      uuid = nil
      if Meda.features.is_enabled(FEATURE_NAME, false)
        uuid = id || generate_rva_id()
        Thread.current.thread_variable_set(@config.verification_api['thread_id_key'], uuid)
      end
      return uuid
    end

    def build_rva_log
      built_list = []
      all_json = get_all_json_data(@config.data_path)
      all_rva_data =  @@log_data_store.decode_collection(@config.verification_api['collection_name'])

      all_rva_data.each { |rva_data|
        json = get_related_json_data(all_json, rva_data, 'json')
        rva_data = add_data_source(DATA_OUTPUT_PROP,
                               rva_data,
                               'json',
                               json)
        built_list.push(rva_data)
      }
      return built_list
    end

    def clear_rva_log
      @@log_data_store.delete(@config.verification_api['collection_name'])
      return true
    end


    #################
    ### private ###


    def add_data_source(operation_key, rva_data, type, ref)
      # puts "saving source with: #{operation_key} , #{type}, #{ref}"

      if rva_data != nil && ref != nil
        temp = {}
        if rva_data.has_key?(operation_key.to_sym)
          temp = temp.merge(rva_data[operation_key.to_sym])
        end
        ref_hash = {type.to_sym => ref}
        temp = temp.merge(ref_hash)
        rva_data = rva_data.merge!(operation_key.to_sym => temp)
      end
      return rva_data
    end


    def generate_rva_id()
      uuid = UUIDTools::UUID.random_create.to_s #timestamp_create.hexdigest
      uuid = "#{@config.verification_api['id_prefix']}#{uuid}"
      return uuid
    end

    # This will parse a meda json file (syntax: one JSON object per line)
    #@param file_path - this is the file path of the meda JSON
    #@returns json_list::Array -list of json objects parsed
    def parse_meda_json(file_path)
      json_list = []
      File.open(file_path, "r").each_line do |line|
        json_list.push JSON.parse(line)
      end
      return json_list
    end

    # This retrieve a list of all json file paths within the meta data directory
    #@param base_path - this is the base path of the meda JSON directory
    #@returns json_files::Array - list of json file paths found
    def get_json_filepaths(base_path)
      glob = '**/*.json'
      file_path = "#{base_path}/#{@config.env}/#{glob}"
      json_files = Dir.glob(file_path)
      return json_files
    end

    # This will parse all meda json files within the meta data folder (syntax: one JSON object per line)
    #@param base_path - this is the file path of the meda JSON
    #@returns json_list::Array - list of json objects parsed
    def get_all_json_data(base_path)
      json_files = get_json_filepaths(base_path)
      json_list = []
      json_files.each  { |path|
        json_list.concat(parse_meda_json(path))
      }
      return json_list
    end


    def get_related_json_data(json_list, rva_data, source_type)
      match = {}
      found = false
      json_list.each { |json_data|
        if rva_data.has_key?(:transaction_ids)
          if json_data['id'].eql? rva_data[:transaction_ids][source_type.to_sym]
            match = json_data
            found = true
          end
        end
        break if found === true
      }
      if found
        return match
      else
        return nil
      end
    end

  end


end