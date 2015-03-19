require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/json'
require 'meda'
require 'meda/collector/connection'
require 'logger'
require 'uuidtools'
require 'meda/services/loader/profile_loader'
require 'meda/services/filter/request_url_filter_service'
require 'meda/services/logging/logging_meta_data_service'
require 'meda/services/validation/validation_service'

module Meda
  module Collector

    # Extends Sinatra:Base to create a Sinatra application implementing the collector's REST API.
    # All operations are delegated to an instance of Meda::Collector::Connection, which implements
    # the desired operation on the given dataset.
    #
    # All routes require the dataset's token to be passed in the "dataset" parameter.
    class App < Sinatra::Base

      set :public_folder, 'static'
      configure { 
        set :show_exceptions, false 
        set :dump_errors, false
      }

      helpers Sinatra::Cookies
      helpers Sinatra::JSON

      helperConfig = {}
      helperConfig["config"] = Meda.configuration
     
      @@logging_meta_data_service = Meda::LoggingMetaDataService.new(helperConfig)
      @@validation_service = Meda::ValidationService.new()

      before do
        @@logging_meta_data_service.setup_meta_logs(request,headers,cookies,request_environment)
      end      

      before do
        if Meda.features.is_enabled("pre_request_log",false)
          logger.info("Starting request... ")
        end
      end

      before do
        if not client_id_cookie_exist?
          logger.debug("client_id doesn't exist, creating client_id")
          uuid = UUIDTools::UUID.random_create.to_s
          set_client_id_cookie(uuid)
          logger.debug("client_id created: #{get_client_id_from_cookie}")
        else
          logger.debug("client_id already created")
        end
        set_client_id_param(get_client_id_from_cookie)
      end

      after do
        if Meda.features.is_enabled("p3p", true)
          response.headers['P3P'] = Meda.configuration.p3p
        end
      end

      after do
        if Meda.features.is_enabled("post_request_log",false)
          @@logging_meta_data_service.add_to_mdc("status_code",response.status)
          logger.info("Ending request... status code #{response.status}")
        end
      end

      error do |e|
        Meda.logger.error(e)
        'Internal Error'
      end

      not_found do
        'Request URL or Method is Not Found'
      end

      # @method post_meda_load
      # @overload post "/meda/load"
      # Testing tool to load data into profile database
      post '/meda/load' do 
        if Meda.features.is_enabled("profile_loader", false)       
          params_hash = JSON.parse(request.body.read)
          dataset = Meda.datasets[params_hash['dataset']]

          store_config = {}
          store_config['config'] = Meda.configuration
          store_config['name'] = dataset.name
          
          profileLoader = Meda::ProfileLoader.new()
          profileLoader.loadWithSomeProfileData(params_hash['amount'],store_config)
          
          respond_with_ok
        else
          logger.warn("profile loader is disabled.")
        end
      end

      # @method post_meda_load_count
      # @overload post "/meda/load"
      # Testing tool to load data into profile database
      post '/meda/load/count' do 
        if Meda.features.is_enabled("profile_loader",false)       
          params_hash = JSON.parse(request.body.read)
          dataset = Meda.datasets[params_hash['dataset']]

          store_config = {}
          store_config['config'] = Meda.configuration
          store_config['name'] = dataset.name
          
          store = Meda::ProfileDataStore.new(store_config)
          result = store.log_size
           json({'count' => result})
        else
          logger.warn("profile loader is disabled.")
        end
      end

      # @method get_index
      # @overload get "/meda"
      # Says hello and gives version number. Useful only to test if service is installed.
      get '/meda' do        
        "Meda version #{Meda::VERSION}"
      end

      # @method get debug info
      # @overload get "/meda/debug"
      # Thread pool data.
      get '/meda/log' do

        logger.debug("debug")
        logger.info("info")
        logger.warn("warn")
        logger.error("error")
        "see logs"
      end

      # @method get_static
      # @overload get "/meda/static/:file"
      # Serves any files in the project's public directory, usually named "static"
      get '/meda/static/:file' do
        path = File.join(settings.public_folder, params[:file])
        send_file(path)
      end

      # @method post_identify_json
      # @overload post "/meda/identify.json"
      # Identifies the user, and returns a meda profile_id
      post '/meda/identify.json', :provides => :json do
        identify_data = raw_json_from_request
        #print_out_params(identify_data)
        profile = settings.connection.identify(identify_data)
        if profile
          json({'profile_id' => profile[:id]})
        else
          logger.error("post /meda/identify.json ==> Unable to find profile")
          respond_with_bad_request
        end
      end

      # @method get_identify_gif
      # @overload get "/meda/identify.gif"
      # Identifies the user, and sets a cookie with the meda profile_id
      get '/meda/identify.gif' do
        profile = settings.connection.identify(params)
        if profile
          set_profile_id_in_cookie(profile['id'])
          respond_with_pixel
        else
          logger.error("get /meda/identify.gif ==> Unable to find profile")
          respond_with_bad_request
        end
      end

      # @method post_profile_json
      # @overload post "/meda/profile.json"
      # Sets attributes on the given profile
      post '/meda/profile.json', :provides => :json do
        profile_data = raw_json_from_request
        #print_out_params(profile_data)
        if @@validation_service.valid_profile_request?(get_client_id_from_cookie, profile_data)
          result = settings.connection.profile(profile_data)
          if result
            respond_with_ok
          else
            logger.error("post /meda/profile.json ==> Invalid result")
            respond_with_bad_request
          end
        else
          logger.error("post /meda/profile.json ==> Invalid request")
          respond_with_bad_request
        end
      end

      # @method delete_profile_json
      # Deletes a given profile by profileid and dataset
      delete '/meda/profile.json', :provides => :json do
        profile_data = raw_json_from_request
        if @@validation_service.valid_profile_request?(get_client_id_from_cookie, profile_data)
          result = settings.connection.delete_profile(profile_data)
          if result
            respond_with_ok
          else
            logger.error("delete /meda/profile.json ==> Invalid result")
            respond_with_bad_request
          end
        else
          logger.error("delete /meda/profile.json ==> Invalid request")
          respond_with_bad_request
        end
      end

      # @method delete_profile_json
      # Deletes a given profile by profileid and dataset
      get '/meda/profile_delete.gif' do

        get_profile_id_from_cookie
        if @@validation_service.valid_request?(get_client_id_from_cookie, params)
          result = settings.connection.delete_profile(params)
          if result
            respond_with_pixel
          else
            logger.error("get_profile_id_from_cookie ==> Unable to delete profile")
            respond_with_bad_request
          end
        else
          logger.error("get_profile_id_from_cookie ==> Invalid request")
          respond_with_bad_request
        end
      end

      # @method post_getprofile_json
      # Displays a profile for given profile_id
      post '/meda/getprofile.json', :provides => :json do
        profile_data = raw_json_from_request
        if @@validation_service.valid_profile_request?(get_client_id_from_cookie, profile_data)
          profile = settings.connection.get_profile_by_id(profile_data)
          if profile
            profile.to_json
          else
            logger.error("post /meda/getprofile.json ==> Unable to find profile")
            respond_with_bad_request
          end
        else
          logger.error("post /meda/getprofile.json ==> Invalid request")
          respond_with_bad_request
        end
      end

      # @method post_getlasthit_json
      # Displays the last hit send to a dataset
      # Requires a dataset
      post '/meda/getlasthit.json', :provides => :json do
        request_data = raw_json_from_request
        if request_data[:dataset]
          last_hit = settings.connection.get_last_hit(request_data)
        else
          logger.error("post /meda/getlasthit.json ==> Invalid request")
          respond_with_bad_request
        end
        if last_hit
          last_hit.to_json
        else
          logger.error("post /meda/getlasthit.json ==> Failed to get last hit")
        end
      end


      # @method get_profile_gif
      # @overload get "/meda/profile.gif"
      # Sets attributes on the given profile
      get '/meda/profile.gif' do
        get_profile_id_from_cookie
        if @@validation_service.valid_profile_request?(get_client_id_from_cookie, params)
          settings.connection.profile(params)
          respond_with_pixel
        else
          logger.error("profile.gif bad request request")
          respond_with_bad_request
        end
      end

      # @method get_utm_gif
      # @overload get "/meda/:dataset/__utm.gif"
      # Accept google analytics __utm.gif formatted hits
      get '/meda/:dataset/__utm.gif' do
        get_profile_id_from_cookie

        if params[:utmt] == 'event'
          utm_data = event_params_from_utm
          if @@validation_service.valid_hit_request?(get_client_id_from_cookie, utm_data)
            settings.connection.track(utm_data)
            respond_with_pixel
          else
            logger.error("get /meda/:dataset/__utm.gif ==> Invalid hit request")
            respond_with_bad_request
          end
        else
          utm_data = page_params_from_utm
          if @@validation_service.valid_hit_request?(get_client_id_from_cookie, utm_data)
            settings.connection.page(utm_data)
            respond_with_pixel
          else
            logger.error("get /meda/:dataset/__utm.gif ==> Invalid hit request")
            respond_with_bad_request
          end
        end
      end

      # @method post_page_json
      # @overload post "/meda/page.json"
      # Record a pageview
      post '/meda/page.json', :provides => :json do
        logger.debug("in page")
        page_data = json_from_request
        if @@validation_service.valid_hit_request?(get_client_id_from_cookie, page_data)
          logger.debug("in page, hit validated")
          settings.connection.page(request_environment.merge(page_data))
          respond_with_ok
        else
          logger.error("post /meda/page.json ==> Invalid hit request")
          respond_with_bad_request
        end
      end

      # @method get_page_gif
      # @overload get "/meda/page.gif"
      # Record a pageview
      get '/meda/page.gif' do
        get_profile_id_from_cookie
        if @@validation_service.valid_hit_request?(get_client_id_from_cookie, params)
          settings.connection.page(request_environment.merge(params))
          respond_with_pixel
        else
          logger.error("get /meda/page.gif ==> Invalid hit request")
          respond_with_bad_request
        end
      end

      # @method post_track_json
      # @overload post "/meda/track.json"
      # Record an event
      post '/meda/track.json', :provides => :json do
        track_data = json_from_request
        if @@validation_service.valid_hit_request?(get_client_id_from_cookie, track_data)
          settings.connection.track(request_environment.merge(track_data))
          respond_with_ok
        else
          logger.error("post /meda/track.json ==> Invalid hit request")
          respond_with_bad_request
        end
      end

      # @method get_track_gif
      # @overload get "/meda/track.gif"
      # Record an event
      get '/meda/track.gif' do
        get_profile_id_from_cookie
        if @@validation_service.valid_hit_request?(get_client_id_from_cookie, params)
          settings.connection.track(request_environment.merge(params))
          respond_with_pixel
        else
          logger.error("get /meda/track.gif ==> Invalid hit request")
          respond_with_bad_request
        end
      end

      # @method get_endsession_gif
      # remove an active identified session with the collector
      get '/meda/endsession.gif' do
        cookies.delete("_meda_profile_id")
        respond_with_pixel
      end


      get 'meda/gettest.page' do

      end
     

      # Config

      configure do
        set :connection, Meda::Collector::Connection.new
      end

      protected

      def json_from_request
        raw_json_from_request
      end

      def raw_json_from_request
        begin
          params_hash = JSON.parse(request.body.read)
          ActiveSupport::HashWithIndifferentAccess.new(params_hash)
        rescue JSON::ParserError => e
          status 422
          json({'error' => 'Request body is invalid'})
        end
      end



      def respond_with_ok
        json({"status" => "ok"})
      end

      def print_out_params(params)
        puts params
      end

      def respond_with_bad_request
        status 400
        json({"status"=>"bad request"})
      end

      def respond_with_pixel
        img_path = File.expand_path('../../../../assets/images/1x1.gif', __FILE__)
        send_file(open(img_path), :type => 'image/gif', :disposition => 'inline')
      end

      def set_profile_id_in_cookie(id)
        cookies[:'_meda_profile_id'] = id
      end

      def get_profile_id_from_cookie
        params[:profile_id] ||= cookies[:'_meda_profile_id']
      end

      def set_client_id_cookie(client_id)
        @@logging_meta_data_service.add_to_mdc("new__collector_client_id", client_id)
        cookies[:'__collector_client_id'] = client_id
      end

      def get_client_id_from_cookie
        cookies[:'__collector_client_id']
      end

      def set_client_id_param(client_id)
        if params[:client_id].blank?
          logger.debug("client_id param is blank")
        else
          logger.debug("overwriting client_id with new value")
        end
        params[:client_id] = client_id
        logger.debug("set client_id param with new value of #{params[:client_id]}")
      end

      def client_id_cookie_exist?
        if cookies[:'__collector_client_id'].blank?
          logger.debug("client_id doesn't exists")
          return false
        else
          logger.debug("client_id already exist")
          return true
        end
      end

      # Extracts hit params from request environment
      def request_environment
        referrer = request.referrer
        params[:referrer] ||= referrer ||= ""
        ActiveSupport::HashWithIndifferentAccess.new({
          :user_ip => remote_ip,
          :referrer => params[:referrer],
          :user_language => request.env['HTTP_ACCEPT_LANGUAGE'],
          :user_agent => request.user_agent
        })
      end

      # Replace Sinatra's default request.ip call.
      # Default gives proxy IPs instead of remote client IP
      def remote_ip
        request.env['HTTP_X_FORWARDED_FOR'].present? ?
          request.env['HTTP_X_FORWARDED_FOR'].strip.split(/[,\s]+/)[0] : request.ip
      end

      # Extracts pageview hit params from __utm request
      def page_params_from_utm
        ActiveSupport::HashWithIndifferentAccess.new({
          :profile_id => cookies[:'_meda_profile_id'],
          :hostname => params[:utmhn],
          :referrer => params[:utmr] || request.referrer,
          :user_ip => params[:utmip] || remote_ip,
          :user_agent => request.user_agent,
          :path => params[:utmp],
          :title => params[:utmdt],
          :user_language => params[:utmul],
          :screen_depth => params[:utmsc],
          :screen_resolution => params[:utmsr]
        })
      end

      # Extracts event hit params from __utm request
      def event_params_from_utm
        parsed_utme = params[:utme].match(/\d\((.+)\*(.+)\*(.+)\*(.+)\)/) # '5(object*action*label*value)'
        ActiveSupport::HashWithIndifferentAccess.new({
          :profile_id => cookies[:'_meda_profile_id'],
          :category => parsed_utme[1],
          :action => parsed_utme[2],
          :label => parsed_utme[3],
          :value => parsed_utme[4],
          :hostname => params[:utmhn],
          :referrer => params[:utmr] || request.referrer,
          :user_ip => params[:utmip] || remote_ip,
          :user_agent => request.user_agent,
          :user_language => params[:utmul],
          :screen_depth => params[:utmsc],
          :screen_resolution => params[:utmsr]
        })
      end


      def logger
        @logger ||= Meda.logger || Logger.new(STDOUT)
      end

    end

  end
end
