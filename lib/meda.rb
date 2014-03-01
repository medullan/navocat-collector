require "meda/version"

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

    attr_accessor :redis

    def initialize
      @redis = REDIS_DEFAULTS.dup
    end
  end
end

Meda.configure do |config|
end

# require "meda/*"

require "meda/dataset"
require "meda/funnel"
require "meda/goal"
require "meda/profile"
require "meda/collector/connection"
require "meda/collector/app"
require "active_support/all"


