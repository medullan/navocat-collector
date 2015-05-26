require 'rubygems'
require 'bundler/setup'
require 'meda'
require 'meda/collector'
require 'newrelic_rpm'

use Rack::Deflater

map "/meda/verifier/assets" do
  if Meda.features.is_enabled("verification_api", false)
    run Rack::Directory.new("./verifier/assets")
  end
end

Meda.configure do |config|
  config.disk_pool = 4
  config.google_analytics_pool = 16
  config.mapdb_path = 'db'
  config.data_path = 'meda_data'
  config.log_path = 'log/my_log.log'
  config.log_level = 1
  config.env = ENV['RACK_ENV'] || config.env

  if not config.verification_api.empty?
    config.verification_api['collection_name'] = "#{config.verification_api['collection_name']}-#{config.env}"

    config.verification_api['private_keys'].each_with_index do |value , index|
      config.verification_api['private_keys'][index] = (value != nil)? value.to_s: nil
    end
  end

end

dataset = Meda::Dataset.new("perf_#{Time.now.to_i}", Meda.configuration)
dataset.token = 'LOCAL_TEST'
dataset.whitelisted_urls = []
dataset.google_analytics = {'record' => false}
Meda.datasets[dataset.token] = dataset


NewRelic::Agent.after_fork(:force_reconnect => true)

run Meda::Collector::App