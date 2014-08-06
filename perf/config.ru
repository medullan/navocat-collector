require 'rubygems'
require 'bundler/setup'
require 'meda'
require 'meda/collector'

Meda.configure do |config|
  config.disk_pool = 4
  config.google_analytics_pool = 16
  config.mapdb_path = 'perf/db'
  config.data_path = 'perf/meda_data'
  config.log_path = 'perf/log/perf.log'
  config.log_level = 1
end

#dataset = Meda::Dataset.new("perf_#{Time.now.to_i}", Meda.configuration)
#dataset.token = 'PERF_TOKEN'
#dataset.google_analytics = {'record' => false}
#Meda.datasets[dataset.token] = dataset

run Meda::Collector::App