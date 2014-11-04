require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/json'
require 'meda'
require 'meda/collector/connection'
require 'logger'

module Meda
  module Collector

    # Extends Sinatra:Base to create a Sinatra application implementing the collector's REST API.
    # All operations are delegated to an instance of Meda::Collector::Connection, which implements
    # the desired operation on the given dataset.
    #
    # All routes require the dataset's token to be passed in the "dataset" parameter.
    class App < Sinatra::Base

      set :public_folder, 'static'

      helpers Sinatra::Cookies
      helpers Sinatra::JSON

      # @method get_index
      # @overload get "/meda"
      # Says hello and gives version number. Useful only to test if service is installed.
      get '/meda' do
        "Meda version #{Meda::VERSION}"
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
          respond_with_bad_request
        end
      end

      # @method get_identify_gif
      # @overload get "/meda/identify.gif"
      # Identifies the user, and sets a cookie with the meda profile_id
      get '/meda/identify.gif' do
        profile = settings.connection.identify(params)
        #print_out_params(params)
        set_profile_id_in_cookie(profile['id'])
        respond_with_pixel
      end

      # @method post_profile_json
      # @overload post "/meda/profile.json"
      # Sets attributes on the given profile
      post '/meda/profile.json', :provides => :json do
        profile_data = raw_json_from_request
        #print_out_params(profile_data)
        result = settings.connection.profile(profile_data)
        if result 
          respond_with_ok
        else
          respond_with_bad_request
        end
      end


      # @method post_getprofile_json
      # @overload post "/meda/getprofile.json"
      # Displays a profile for given profile_id
      # NOTE: This needs to be modified in keeping with the RESTful interface
      # Did not get the time to
      post '/meda/getprofile.json', :provides => :json do
        profile_data = raw_json_from_request
        profile = settings.connection.get_profile_by_id(profile_data)
        if profile 
          profile.to_json
        else
          respond_with_bad_request
        end
      end


      # @method get_profile_gif
      # @overload get "/meda/profile.gif"
      # Sets attributes on the given profile
      get '/meda/profile.gif' do
        get_profile_id_from_cookie
        #print_out_params(params)
        settings.connection.profile(params)
        respond_with_pixel
      end

      # @method get_utm_gif
      # @overload get "/meda/:dataset/__utm.gif"
      # Accept google analytics __utm.gif formatted hits
      get '/meda/:dataset/__utm.gif' do
        get_profile_id_from_cookie

        if params[:utmt] == 'event'
          utm_data = event_params_from_utm
          if valid_hit_request?(utm_data)
            settings.connection.track(utm_data)
            respond_with_pixel
          else
            respond_with_bad_request
          end
        else
          utm_data = page_params_from_utm
          if valid_hit_request?(utm_data)
            settings.connection.page(utm_data)
            respond_with_pixel
          else
            respond_with_bad_request
          end
        end
      end

      # @method post_page_json
      # @overload post "/meda/page.json"
      # Record a pageview
      post '/meda/page.json', :provides => :json do
        page_data = json_from_request
        #print_out_params(page_data) 
        if valid_hit_request?(page_data)
          settings.connection.page(get_saved_client_id(clean_path(request_environment.merge(page_data))))
          respond_with_ok
        else
          respond_with_bad_request
        end
      end

      # @method get_page_gif
      # @overload get "/meda/page.gif"
      # Record a pageview
      get '/meda/page.gif' do
        get_profile_id_from_cookie
        if valid_hit_request?(params)
          #print_out_params(params)
          settings.connection.page(get_saved_client_id(clean_path(request_environment.merge(params))))
          respond_with_pixel
        else
          respond_with_bad_request
        end
      end

      # @method post_track_json
      # @overload post "/meda/track.json"
      # Record an event
      post '/meda/track.json', :provides => :json do
        track_data = json_from_request
        #print_out_params(track_data)
        if valid_hit_request?(track_data)
          settings.connection.track(get_saved_client_id(clean_path(request_environment.merge(track_data))))
          respond_with_ok
        else
          respond_with_bad_request
        end
      end

      # @method get_track_gif
      # @overload get "/meda/track.gif"
      # Record an event
      get '/meda/track.gif' do
        get_profile_id_from_cookie
        if valid_hit_request?(params)
          settings.connection.track(get_saved_client_id(clean_path(request_environment.merge(params))))
          respond_with_pixel
        else
          respond_with_bad_request
        end
      end

      # Config

      configure do
        set :connection, Meda::Collector::Connection.new
      end

      protected

      # Clean the path variable to only include query string params if the url is in a whitelist
      def clean_path(params)
        begin
          current_path = params[:path]
          if current_path.include? "?" 

            #Replace whitelist with commented line below to test sample.html locally
            #whitelisted_paths = [/\/sample\.html\?toolid=3563/,/\/sample\.html\?.*Fcreate_account$/,/\/sample\.html\?.*Fcreate_account&_58_resume=$/]
            
            whitelisted_paths = [/\/hra\/lobby\.aspx\?toolid=3563/,/\/web\/guest\/myblue\?.*Fcreate_account$/,/\/web\/guest\/myblue\?.*Fcreate_account&_58_resume=$/]
            regex_of_paths = Regexp.union(whitelisted_paths)

            if (!regex_of_paths.match(current_path)) 
              params[:path] = current_path[0..(current_path.index("?")-1)]
            end
          end
        rescue StandardError => e
          logger.error("Failure cleaning path: #{params[:path]}")
          logger.error(e)
        end
        params
      end

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

      def valid_hit_request?(request_params)
        [:dataset, :profile_id, :client_id, :path].all? {|p| request_params[p].present? }
      end

      def get_saved_client_id(data)
        begin
          #data should already be validated for this request
          profile_id = data[:profile_id]
          if profile_id != '471bb8f0593711e48c1e44fb42fffeaa' 
            temp = ActiveSupport::HashWithIndifferentAccess.new({
              :dataset => data[:dataset],
              :profile_id => profile_id,
              :client_id => data[:client_id]
            })
            current_path = data[:path]
            if (current_path.include? "/pilot/landingpage") || (current_path.include? "/members/myblue/dashboard") 
              settings.connection.profile(temp)
            else
              profile = settings.connection.get_profile_by_id(temp)
              if profile 
                profile_client_id = profile[:client_id]
                if profile_client_id
                  data[:client_id] = profile_client_id
                end
              end
            end
          end
        rescue StandardError => e
          logger.error("Failure getting client_id from profile")
          logger.error(e)
        end
        data
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

    end

  end
end

