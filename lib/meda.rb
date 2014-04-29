require File.dirname(File.absolute_path(__FILE__)) + '/meda/version.rb'
Dir.glob(File.dirname(File.absolute_path(__FILE__)) + '/meda/core/*.rb') {|file| require file}
require "active_support/all"
require "connection_pool"
require 'psych'

module Meda

  REDIS_POOL_DEFAULT = 1 # thread
  REDIS_TIMEOUT_DEFAULT = 5 # seconds
  DISK_POOL_DEFAULT = 2 # threads
  GA_POOL_DEFAULT = 2 # threads

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def self.logger
    if @logger.nil? && Meda.configuration.log_path.present?
      FileUtils.mkdir_p(File.dirname(Meda.configuration.log_path))
      FileUtils.touch(Meda.configuration.log_path)
      @logger = Logger.new(Meda.configuration.log_path)
      @logger.level = Meda.configuration.log_level || Logger::INFO
    end
    @logger
  end

  def self.redis
    if @redis_pool.nil? && Meda.configuration.redis.present?
      pool_size = Meda.configuration.redis['pool'] || REDIS_POOL_DEFAULT
      @redis_pool = ConnectionPool.new(size: pool_size, timeout: REDIS_TIMEOUT_DEFAULT) do
        Redis.new(Meda.configuration.redis)
      end
    end
    @redis_pool
  end

  def self.datasets
    if @datasets.nil?
      @datasets = {}
      begin
        config = Psych.load(File.open('datasets.yml'))
        config.each do |d_name, d_config|
          d = Meda::Dataset.new(d_name)
          d_config.each_pair { |key, val| d.send("#{key}=", val) }
          @datasets[d.token] = d
        end
      rescue Errno::ENOENT
        puts "Warning: datasets.yml missing, please create datasets manually"
      end
    end
    @datasets
  end

  class Configuration

    REDIS_DEFAULTS = {
      :host => 'localhost',
      :port => 6379,
      :password => nil
    }

    attr_accessor :redis, :data_path, :log_path, :log_level, :disk_pool, :google_analytics_pool

    def initialize
      @redis = REDIS_DEFAULTS.dup
      @disk_pool = DISK_POOL_DEFAULT
      @google_analytics_pool = GA_POOL_DEFAULT
    end

    def []=(key, val)
      send("#{key}=", val)
    end
  end
end

Meda.configure do |config|
  begin
    app_config = Psych.load(File.open('application.yml'))[ENV['RACK_ENV'] || 'development']
    app_config.each_pair { |key, val| config[key] = val }
  rescue Errno::ENOENT
    puts "Warning: Missing application.yml, please configure manually"
  end
end

Meda

