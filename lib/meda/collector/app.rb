require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/json'
require 'meda'
require 'meda/collector/connection'

module Meda
  module Collector

    class App < Sinatra::Base

      set :public_folder, 'static'

      helpers Sinatra::Cookies
      helpers Sinatra::JSON

      get '/' do
        "Meda version #{Meda::VERSION}"
      end

      # Serve any files from the /static directory

      get '/static/:file' do
        path = File.join(settings.public_folder, params[:file])
        send_file path
      end

      # Identify

      post '/identify.json', :provides => :json do
        identify_data = json_from_request
        user = settings.connection.identify(identify_data)
        json({"profile_id" => user.profile_id})
      end

      get '/identify.gif' do
        user = settings.connection.identify(params)
        set_profile_id_in_cookie(user.profile_id)
        respond_with_pixel
      end

      # Profile

      post '/profile.json', :provides => :json do
        profile_data = json_from_request
        settings.connection.profile(profile_data)
        respond_with_ok
      end

      get '/profile.gif' do
        get_profile_id_from_cookie
        settings.connection.profile(params)
        respond_with_pixel
      end

      # Accept google analytics __utm.gif formatted hits

      get '/:dataset/__utm.gif' do
        get_profile_id_from_cookie
        if params[:utmt] == 'event'
          settings.connection.track(event_params_from_utm)
        else
          settings.connection.page(page_params_from_utm)
        end
        respond_with_pixel
      end

      # Page

      post '/page.json', :provides => :json do
        page_data = json_from_request
        if(page_data['profile_id'] !=  '351bb960ecd711e3a0a822000ab93e79')
          page_data['user_id'] = page_data['profile_id']
        end
        page_data['user_ip'] = request.env['HTTP_X_FORWARDED_FOR'].split(', ')[0] 
        settings.connection.page(page_data)
        respond_with_ok
      end

      get '/page.gif' do
        get_user_ip_from_header_param
        get_user_id_for_logged_in_user
        get_profile_id_from_cookie
        settings.connection.page(params.merge(request_environment))
        respond_with_pixel
      end

      # Track

      post '/track.json', :provides => :json do
        track_data = json_from_request
        if(track_data['profile_id'] !=  '351bb960ecd711e3a0a822000ab93e79')
          track_data['user_id'] = track_data['profile_id']
        end
        track_data['user_ip'] = request.env['HTTP_X_FORWARDED_FOR'].split(', ')[0] 
        settings.connection.track(track_data)
        respond_with_ok
      end

      get '/track.gif' do
        get_user_ip_from_header_param
        get_user_id_for_logged_in_user
        get_profile_id_from_cookie
        settings.connection.track(params)
        respond_with_pixel
      end

      # Config

      configure do
        set :connection, Meda::Collector::Connection.new
      end

      protected

      def json_from_request
        begin
          JSON.parse(request.body.read).symbolize_keys
        rescue StandardError => e
          status 422
          json({'error' => 'Request body is invalid'})
        end
      end

      def get_user_ip_from_header_param
        params[:user_ip] = request.env['HTTP_X_FORWARDED_FOR'].split(', ')[0] 
      end
        
      def get_user_id_for_logged_in_user
        if(params['profile_id'] !=  '351bb960ecd711e3a0a822000ab93e79')
          params['user_id'] = params['profile_id']
        end
      end

      end
      def respond_with_ok
        json({"status" => "ok"})
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

      #

      def request_environment
        {
          :user_ip => request.env['REMOTE_ADDR'],
          :referrer => request.env['HTTP_REFERER'],
          :user_agent => request.env['HTTP_USER_AGENT']
        }
      end

      def page_params_from_utm
        {
          :profile_id => cookies[:'_meda_profile_id'],
          :hostname => params[:utmhn],
          :referrer => params[:utmr] || request.env['HTTP_REFERER'],
          :user_ip => mask_ip(params[:utmip] || request.env['REMOTE_ADDR']),
          :user_agent => request.env['HTTP_USER_AGENT'],
          :path => params[:utmp],
          :title => params[:utmdt],
          :user_language => params[:utmul],
          :screen_depth => params[:utmsc],
          :screen_resolution => params[:utmsr]
        }
      end

      def event_params_from_utm
        parsed_utme = params[:utme].match(/\d\((.+)\*(.+)\*(.+)\*(.+)\)/) # '5(object*action*label*value)'
        {
          :profile_id => cookies[:'_meda_profile_id'],
          :category => parsed_utme[1],
          :action => parsed_utme[2],
          :label => parsed_utme[3],
          :value => parsed_utme[4],
          :hostname => params[:utmhn],
          :referrer => params[:utmr] || request.env['HTTP_REFERER'],
          :user_ip => mask_ip(params[:utmip] || request.env['REMOTE_ADDR']),
          :user_agent => request.env['HTTP_USER_AGENT'],
          :user_language => params[:utmul],
          :screen_depth => params[:utmsc],
          :screen_resolution => params[:utmsr]
        }
      end

      def mask_ip(ip)
        subnet, match, hostname = ip.rpartition('.')
        return subnet + '.0'
      end

    end

  end
end

