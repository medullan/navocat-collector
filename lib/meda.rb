require File.dirname(File.absolute_path(__FILE__)) + '/meda/version.rb'
Dir.glob(File.dirname(File.absolute_path(__FILE__)) + '/meda/core/*.rb') {|file| require file}
require "active_support/all"

module Meda

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration

    REDIS_DEFAULTS = {
      :host => 'localhost',
      :port => 6379,
      :password => nil
    }

    attr_accessor :redis, :data_path, :log_path, :log_level

    def initialize
      @redis = REDIS_DEFAULTS.dup
    end

    def []=(key, val)
      send("#{key}=", val)
    end
  end
end

Meda.configure do |config|
end

Meda

