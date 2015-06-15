require_relative '../profile/profile_service.rb'
require_relative '../datastore/redisdb/redisdb_store.rb'
require 'meda/services/profile/one_key/profile_id_service'
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
    LOG_KEY_IDS = { :cid => 'cid', :rid => 'rid', :pid => 'pid', :sort => 'sort' }
    LOG_KEY_COUNTER = 'rva_log_key_counter'

    def initialize(config)
      @config=config
      helper_config = {}
      @@log_data_store = Meda::RedisDbStore.new(config)
    end

    ### public ###

    def start_rva_log (type, data, request, cookies)
      if Meda.features.is_enabled(FEATURE_NAME, false)
        rva_id = generate_rva_id
        profile_id = data.key?(:profile_id) ? data[:profile_id] : cookies['_meda_profile_id']
        client_id = cookies['__collector_client_id']
        input = data.key?(:request_input) ? data[:request_input] : nil
        sort_key = @@log_data_store.increment(LOG_KEY_COUNTER)

        if profile_id == nil
          profile_id = get_profile_id_from_request(input)
        end
          
        end_point_type = data.key?(:end_point_type) ? data[:end_point_type] : nil
        rva_data = {
            :id => rva_id,
            :sort_key => sort_key,
            :profile_id => profile_id, :client_id => client_id,
            :type => type,
            :http => {
                :start_time => data[:start_time].iso8601.to_s, :end_time => nil,:url => request.url,
                :method => request.request_method, :request_input => input, :response => nil, :end_point_type => end_point_type
            }
        }
        log_key = create_log_key(
            @config.verification_api['collection_name'],
            profile_id,
            client_id,
            rva_id,
            sort_key.to_s)
        # puts log_key
        set_rva_id(log_key)
        delete_logs_outside_limit
        save_log(log_key, rva_data)
      end
    end

    def end_rva_log (response=nil)
      if Meda.features.is_enabled(FEATURE_NAME, false)
        rva_id = get_rva_id()
        if rva_id != nil
          rva_data = get_log(rva_id)
          rva_data = parse_log(rva_data)
          puts rva_data
          if rva_data != nil
            rva_data['http']['end_time'] = Time.now.iso8601.to_s
            rva_data['http']['response'] = response
            save_log(rva_id, rva_data)
          end
        end

      end
    end

    def private_key_present? (key)
      if Meda.features.is_enabled(FEATURE_NAME, false)
        if key != nil && @config.verification_api['private_keys'].include?(key)
          return true
        end
      end
      return false
    end

    def add_json_ref(ref)
      rva_id = get_rva_id()
      rva_data = get_log(rva_id)
      rva_data = parse_log(rva_data)
      data = add_data_source(TRANS_IDS_PROP,
                             rva_data,
                             'json',
                             ref)
      save_log(rva_id, data)

      return data
    end

    def add_ga_data(ref)

      rva_id = get_rva_id()
      rva_data = get_log(rva_id)
      rva_data = parse_log(rva_data)

      data = add_data_source(DATA_OUTPUT_PROP,
                             rva_data,
                             'ga',
                             ref)

      save_log(rva_id, data)
      return data
    end

    def build_rva_log(pattern)
      built_list = []
      all_json = get_all_json_data(@config.data_path)
      all_rva_data =  get_logs(pattern)

      all_rva_data.each { |rva_data|
        rva_data = parse_log(rva_data)
        json = get_related_json_data(all_json, rva_data, 'json')
        rva_data = add_data_source(DATA_OUTPUT_PROP,
                               rva_data,
                               'json',
                               json)
        built_list.push(rva_data)
      }
      built_list
    end

    def clear_rva_log(filter=nil)
      data = get_log_keys(pattern)
      data.push(LOG_KEY_COUNTER)
      delete_logs(data)
      return true
    end

    def get_rva_id()
      id = nil
      if Meda.features.is_enabled(FEATURE_NAME, false)
        id =   Thread.current.thread_variable_get(@config.verification_api['thread_id_key'])
      end
      id
    end

    def set_rva_id(id = nil)
      uuid = nil
      if Meda.features.is_enabled(FEATURE_NAME, false)
        uuid = id
        Thread.current.thread_variable_set(@config.verification_api['thread_id_key'], uuid)
      end
      return uuid
    end


    #################
    ### private ###

    def save_log(log_key, rva_data)
      @@log_data_store.set(log_key, rva_data.to_json)
    end

    def get_log(log_key)
      @@log_data_store.get(log_key)
    end

    def get_logs(pattern)
      # pattern = get_all_logs_pattern
      data = get_log_keys(pattern)
      @@log_data_store.multi_decode(data)
    end

    def get_pattern(filter)
      prefix = get_all_logs_pattern
      if !filter.nil?
        if !filter['filter_key'].nil? &&
            !filter['filter_key'].empty? &&
            !filter['filter_value'].nil? &&
            !filter['filter_value'].empty?
          value = filter['filter_value']
          key = filter['filter_key']
          filter_pattern = "#{key}(#{value})"
          template = "#{prefix}#{filter_pattern}*"
          return template
        end
      end
      prefix
    end

    def get_log_keys(pattern)
      @@log_data_store.scan_keys(pattern, 0, @config.verification_api['limit'])
    end

    def parse_log(log)
      if !log.nil? && log.is_a?(String)
        return JSON.parse(log)
      end
      log
    end

    def sort_log_keys(values, asc=true)
      if !values.nil? && !values.empty?
        values.sort! { |a, b|
          a = get_value_from_log_key(a, LOG_KEY_IDS[:sort])
          b = get_value_from_log_key(b, LOG_KEY_IDS[:sort])
          # a.to_i <=> b.to_i
          (asc) ?  a.to_i <=> b.to_i :  b.to_i <=> a.to_i
        }
        # return (asc) ? values : values.reverse
      end
      values
    end

    def get_ids_for_logs_outside_limit(org_list)
      limit = @config.verification_api['limit']
      values = []
      if !org_list.nil? && org_list.length > limit
        num_items_to_delete = org_list.length - limit
        return org_list[0...(num_items_to_delete)]
      end
      values
    end
    def delete_logs_outside_limit
      pattern = get_all_logs_pattern
      puts pattern
      data = sort_log_keys(get_log_keys(pattern))
      list_to_delete = get_ids_for_logs_outside_limit(data)
      puts list_to_delete
      if !list_to_delete.empty?
        delete_logs(list_to_delete)
      end
    end

    def get_all_logs_pattern
      "#{@config.verification_api['collection_name']}|*"
    end

    def delete_logs(ids)
      @@log_data_store.delete(ids)
    end

    def eval_log_key_value(value)
      result = 'none'
      if !value.nil?
        value = value.to_s
        if !value.empty?
          return value
        end
      end
      return result
    end

    # eg. rva|pid(none)|cid(456)|rid(rva-789)|sort(1433992503)|
    def create_log_key(collection, profile_id, client_id, rva_id, sort_key)
      delim = '|'
      collection = collection || 'rva'
      key_template = "#{(collection)}" +
          "#{delim}" +
          "#{LOG_KEY_IDS[:pid]}(#{eval_log_key_value(profile_id)})" +
          "#{delim}" +
          "#{LOG_KEY_IDS[:cid]}(#{eval_log_key_value(client_id)})" +
          "#{delim}" +
          "#{LOG_KEY_IDS[:rid]}(#{eval_log_key_value(rva_id)})" +
          "#{delim}" +
          "#{LOG_KEY_IDS[:sort]}(#{eval_log_key_value(sort_key)})" +
          "#{delim}"
    end

    def get_value_from_log_key(log_key, key_id)
      result = get_key_value_pair_from_log_key(key_id, log_key)
      value = string_between_markers(result, '(', ')')
    end

    def get_key_value_pair_from_log_key(key_id, log_key)
      regex_str = "((?:(#{key_id})[^\\|]*))"
      regex = Regexp.new regex_str
      result = log_key.scan(regex).last.first
    end

    def string_between_markers (str, marker1, marker2)
      str[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
    end

    def get_hash_from_log_key(log_key)
      keys = LOG_KEY_IDS.values
      hash = {}
      keys.each { |key_id|
        value = get_value_from_log_key(log_key, key_id)
        hash.merge!(key_id => value)
      }
      hash
    end

    def get_profile_id_from_request(input)
      profile_id = nil
      if !input.nil?
        if input.key?(:profile_id)
          profile_id = input[:profile_id]
        else if input.key?('profile_id')
               profile_id = input['profile_id']
             end
        end
      end
      profile_id
    end

    def add_data_source(operation_key, rva_data, type, ref)
      # puts "saving source with: #{operation_key} , #{type}, #{ref}"

      if rva_data != nil && ref != nil
        temp = {}
        if rva_data.has_key?(operation_key)
          temp = temp.merge(rva_data[operation_key])
        end
        ref_hash = { type => ref }
        temp = temp.merge(ref_hash)
        rva_data = rva_data.merge!(operation_key => temp)
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
        if rva_data.has_key?('transaction_ids')
          if json_data['id'].eql? rva_data['transaction_ids'][source_type]
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