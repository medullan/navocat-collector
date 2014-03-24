require 'rack/test'
require 'meda'

module RSpecMixin
  include Rack::Test::Methods
  def app() Meda::Collector::App end
end

RSpec.configure { |c| c.include RSpecMixin }

# Also needs to set up and tear down a redis server for the test
# Needs to flush keys between every spec

