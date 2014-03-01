require 'sinatra/base'

module Meda
  module Collector

    class App < Sinatra::Base

      set :connection, Meda::Collector::Connection.new
      set :img_path, File.expand_path('../../../../assets/images/1x1.gif', __FILE__)

      get '/' do
        'Hello world!'
      end

      get '/identify.json' do
        user = settings.connection.identify(params)
        user.marshal_dump.to_json
      end

      get '/profile.json' do
        settings.connection.profile(params)
        'ok'
      end

      get '/event.json' do
        settings.connection.event(params)
        'ok'
      end

      get '/event.gif' do
        settings.connection.event(params)
        send_file(open(settings.img_path), :type => 'image/gif', :disposition => 'inline')
      end
    end

  end
end

