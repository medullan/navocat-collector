require 'sinatra/base'
require 'sinatra/cookies'
require 'meda'
require 'meda/collector/connection'

module Meda
  module Collector

    class App < Sinatra::Base

      connection = Meda::Collector::Connection.new
      set :connection, connection
      set :public_folder, 'static'

      helpers Sinatra::Cookies

      get '/' do
        "Meda version #{Meda::VERSION}"
      end

      # Serve any files from the /static directory

      get '/static/:file' do
        path = File.join(settings.public_folder, params[:file])
        send_file path
      end

      # Identify

      get '/identify.json' do
        user = settings.connection.identify(params)
        set_profile_id_in_cookie(user.profile_id)
        user.marshal_dump.to_json
      end

      get '/identify.gif' do
        user = settings.connection.identify(params)
        set_profile_id_in_cookie(user.profile_id)
        respond_with_pixel
      end

      # Profile

      get '/profile.json' do
        get_profile_id_from_cookie
        settings.connection.profile(params)
        respond_with_ok
      end

      get '/profile.gif' do
        get_profile_id_from_cookie
        settings.connection.profile(params)
        respond_with_pixel
      end

      # Accept google analytics __utm.gif formatted hits

      get '/__utm.gif' do
        get_profile_id_from_cookie
        if params[:utmt] == 'event'
          settings.connection.track(event_params_from_utm)
        else
          settings.connection.page(page_params_from_utm)
        end
        respond_with_pixel
      end

      # Page

      get '/page.json' do
        get_profile_id_from_cookie
        settings.connection.page(params)
        respond_with_ok
      end

      get '/page.gif' do
        get_profile_id_from_cookie
        settings.connection.page(params.merge(request_environment))
        respond_with_pixel
      end

      # Track

      get '/track.json' do
        get_profile_id_from_cookie
        settings.connection.track(params)
        respond_with_ok
      end

      get '/track.gif' do
        get_profile_id_from_cookie
        settings.connection.track(params)
        respond_with_pixel
      end

      # Config

      configure :production, :development do
        enable :logging
      end

      protected

      def respond_with_ok
        {"status" => "ok"}.to_json
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
          :remote_address => request.env['REMOTE_ADDR'],
          :http_referer => request.env['HTTP_REFERER'],
          :http_user_agent => request.env['HTTP_USER_AGENT']
        }
      end

      def page_params_from_utm
        {
          :name => params[:utmp],
          :profile_id => cookies[:'_meda_profile_id']
        }
      end

      def event_params_from_utm
        {
          :name => params[:utme],
          :profile_id => cookies[:'_meda_profile_id']
        }
      end

    end

  end
end

