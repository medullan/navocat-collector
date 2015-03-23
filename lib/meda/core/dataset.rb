require 'ostruct'
require 'uuidtools'
require 'digest'
require 'csv'
require 'securerandom'
require 'staccato'
require 'logger'
require 'meda'
require 'meda/services/logging/logging_meta_data_service'
require 'meda/services/ga_debug/ga_debug_service'

module Meda

  # Dataset manages a single "bucket" of data in a meda instance.
  # Each Dataset has its own configuration, and its data is stored in a separate DB.
  # This class implements most of the logic for each operation (identify, track, etc),
  # and also the logic for writing to disk and Google Analytics.
  class Dataset

    attr_reader :data_uuid, :meda_config, :hit_filter
    attr_accessor :name,:google_analytics, :token, :whitelisted_urls, :enable_data_retrivals, :hit_filter, :filter_file_name, :filter_class_name, :enable_profile_delete

    # Readers primarily used for tests, not especially thread-safe :p
    attr_reader :last_hit, :last_disk_hit, :last_ga_hit, :hit_filter

    def initialize(name, meda_config={})
      @name = name
      @meda_config = meda_config
      @data_uuid = UUIDTools::UUID.timestamp_create.hexdigest
      @data_paths = {}
      @after_identify = lambda {|dataset, user| }
      helperConfig = {}
      helperConfig["config"] = Meda.configuration
      @logging_meta_data_service = Meda::LoggingMetaDataService.new(helperConfig)
      @@ga_debug_service = Meda::GAHitDebugService.new()
    end

    def identify_profile(info)
      profile = store.find_or_create_profile(info)
      @after_identify.call(self, profile)
      logger.debug("profile #{profile}")
      return profile
    end

    def add_event(event_props)
      event_props[:time] ||= DateTime.now.to_s
      event_props[:category] ||= 'none'
      event = Meda::Event.new(event_props, self)
      add_hit(event)
    end

    def add_pageview(page_props)
      page_props[:time] ||= DateTime.now.to_s
      pageview = Meda::Pageview.new(page_props, self)
      add_hit(pageview)
    end

    def add_hit(hit)
      if hit.profile_id
        profile = store.get_profile_by_id(hit.profile_id)
        if profile
          profile.delete('id')
          hit.profile_props = profile
        else
          logger.debug("add_hit ==> Unable to find profile")
        end
      else
        # Hit has no profile
        # Leave it anonymous-ish for now. Figure out what to do later.
        logger.debug("add_hit ==> Hit has no profile id")
      end

      hit = custom_hit_filter(hit)

      if(Logging.mdc["meta_logs"].to_s.length>0)
        hit.meta_logs = Logging.mdc["meta_logs"].to_s
      end
      @last_hit = hit
      hit.validate!

      hit
    end

    def custom_hit_filter(hit)
      if(!hit_filter.nil?)
        hit = hit_filter.filter_hit(hit,self)
      end
      hit
    end

    def set_profile(profile_id, profile_info)
      store.set_profile(profile_id, profile_info)
    end

    def get_profile(profile_id)
      store.get_profile_by_id(profile_id)
    end

    def delete_profile(profile_id)
      if(enable_profile_delete)
        return store.delete_profile(profile_id)
      end
      logger.warn("delete_profile ==> Unable to delete profile")
      return false
    end

    def stream_to_ga?
      !!google_analytics && !!google_analytics['record']
    end


    def stream_hit_to_disk(hit)
      begin
        Logging.mdc["meta_logs"] = hit.meta_logs
        logger.info("Starting to write hit to DISK")
        directory = File.join(meda_config.data_path, path_name, hit.hit_type_plural, hit.day) # i.e. 'meda_data/name/events/2014-04-01'
        unless @data_paths[directory]
          # create the data directory if it does not exist
          @data_paths[directory] = FileUtils.mkdir_p(directory)
        end

        filename = "#{hit.hour}-#{self.data_uuid}.json".gsub(':', '-')  #Replace : with - because can't save files with : on windows
        path = File.join(directory, filename)

        File.open(path, 'a') do |f|
          f.puts(hit.to_json)
        end

        @last_disk_hit = {
          :hit => hit, :path => path, :data => hit.to_json
        }

        @logging_meta_data_service.add_to_mdc("disk_hit_id", hit.id)
        @logging_meta_data_service.add_to_mdc("disk_hit_path", path)
        logger.info("wrote hit to disk")
      rescue StandardError => e
        logger.error("Failure writing hit #{hit.id} to #{path}")
        logger.error(e)
      end
      true
    end

    def stream_hit_to_ga(hit)
      begin
        Logging.mdc["meta_logs"] = hit.meta_logs
        logger.info("Starting to stream hit to GA")
        @last_ga_hit = {:hit => hit, :staccato_hit => nil, :response => nil}
        return unless stream_to_ga?

        tracker = Staccato.tracker(hit.tracking_id, hit.client_id)
      
        if hit.hit_type == 'pageview'
          ga_hit = Staccato::Pageview.new(tracker, hit.as_ga)
        elsif hit.hit_type == 'event'
          ga_hit = Staccato::Event.new(tracker, hit.as_ga)
        end

        if !hit.profile_id.blank?
          google_analytics['custom_dimensions'].each_pair do |dim, val|
            #The naming of profile fields in the json request to fields in the dataset.yml must be identical
            #The index of cust. dim fields in the datasets.yml must be the same for the index of custom dimensions in GA
            #puts("Dimension: #{dim} - Index #{val['index']} - Mapped Value: #{hit.profile_props[dim]}")
            if(val && hit.profile_props)
              ga_hit.add_custom_dimension(val['index'], hit.profile_props[dim])
            end
          end
        end

        @last_ga_hit[:staccato_hit] = ga_hit

        if Meda.features.is_enabled("google_analytics_debug", false)

          @last_ga_response, @last_debug_ga_response = ga_hit.track_debug!

          @@ga_debug_service.debug_ga_info(@last_debug_ga_response)
        else
          @last_debug_ga_response = ga_hit.track!
        end

        @last_ga_hit[:response] = @last_debug_ga_response

        @logging_meta_data_service.add_to_mdc("ga_hit_id", hit.id)

        logger.info("wrote hit to google analytics")
        logger.debug(ga_hit.inspect)

      rescue StandardError => e
        logger.error("Failure writing hit #{hit.id} to GA")
        logger.error(e)
      end
      true
    end

    def after_identify(&block)
      @after_identify = block
    end

    def path_name
      name.downcase.gsub(' ', '_')
    end

    def store
      if @profile_store.nil?
          store_config ={}
          store_config["name"] = path_name
          store_config["config"] = @meda_config
          @profile_store = Meda::ProfileService.new(store_config)
      end
      @profile_store
    end

    protected
      def logger
        Meda.logger || Logger.new(STDOUT)
      end
  end
end
