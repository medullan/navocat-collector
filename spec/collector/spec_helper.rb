ENV['RACK_ENV'] = 'test'

puts 'Loading test environment'
require 'rspec'
require 'rr'
require 'webmock/rspec'
require 'rack/test'

puts 'Loading meda'
require 'meda'
require 'meda/collector'

module RSpecMixin
  include Rack::Test::Methods
  def app() Meda::Collector::App end
end

RSpec.configure { |c| c.include RSpecMixin }

WebMock.disable_net_connect!


Meda.configure do |config|
  config.data_path = 'meda_data'
  config.log_path = 'log/test.log'
  config.log_level = 3
  config.hash_salt = ""
  config.env = 'test'
  config.redis = {:host => 'localhost', :port => 6379, :password => nil, :pool => 10, :time_out => 15}
end

# Also needs to set up and tear down a redis server for the test
# Needs to flush keys between every spec
puts 'Running examples'

