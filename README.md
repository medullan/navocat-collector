# Navocat Collector
=======
[ ![Codeship Status for medullan/navocat-collector](https://codeship.com/projects/257cb380-5615-0132-3f01-16afe4cead14/status)](https://codeship.com/projects/49450)

The collector gem currently provides a collector application that is used to gather analytics events from web browsers, mobile apps or back-end servers, and send page views and events to Google Analytics.

The collector is written in Sinatra and deployed with the puma webserver.

## Dependencies

The collector application requires jRuby 1.7+ and Java 1.6+.

To store profile data, the collector uses MapDB, a pure-java embedded key-value store database. The jar files for MapDB are included in the collector gem, and are plaform independent.

## Basic Application Setup

To create your own collector application, create a new git repo that will use the collector gem.

### Gemfile

Add a Gemfile to the repo, and `bundle install`. Note that your git user must have access to this github repo, or you must use a github url that includes the credentials of a github user that has access.

```ruby
# Gemfile
source 'https://rubygems.org'
gem 'meda', :git => 'github.com/medullan/navocat-collector.git'
gem 'puma'
```

### meda.yml

The application configuration file (meda.yml) defines the location of the data files, log files and other essential functionality. Add this file in the root of the project, and it will be loaded automatically when the server starts. You should provide different configuration options for different Rack environments (RACK_ENV).

Check `CONFIGURATION.md` for comprehensive configuration information.

This example file demonstrates all acceptable configuration options.

```yaml
# meda.yml
development:
  disk_pool: 2
  google_analytics_pool: 2
  mapdb_path: db
  data_path: data
  log_path: log/development.log
  log_level: 0

production:
  disk_pool: 4
  google_analytics_pool: 16
  mapdb_path: db
  data_path: meda_data
  log_path: log/production.log
  log_level: 1
```

### datasets.yml

The dataset configuration file (datasets.yml) defines the buckets into which analytics data is collected, and how that data is treated. The data for each dataset is stored in a separate MapDB database, and also in a separate path on the filesystem.

Here is a sample file:

```yaml
# datasets.yml (sample)
production:
  token: afc0a6c8c73211e3aaf844fb42fffe8c
  filter_file_name: yourfilter.rb (path to filter.rb)
  filter_class_name: YourFilter (filter class name)
  google_analytics:
    record: true
    tracking_id: UA-47758842
    custom_dimensions:
      age:
        index: 1
      gender:
        index: 2
      segment:
        index: 3

staging:
  token: b6822676c73211e3aaf844fb42fffe8c
  google_analytics:
    record: false

development:
  token: c2e02c92c73211e3aaf844fb42fffe8c
  google_analytics:
    record: false
```

### config.ru

Add a `config.ru` file to your project to configure the rack environment to run the collector. 
A sample file which includes a custom filter may look like this:

```ruby
# config.ru

require 'rubygems'
require 'bundler/setup'
require 'meda'
require 'meda/collector'

run Meda::Collector::App
```

## Sample filter for dataset.yml config
```ruby
class YourFilter 
	def filter(hit) 
	   puts "-----\nin your filter!\n------"
	   hit
	end
end



```

## Run the collector

We suggest running the collector in Puma. Puma is a multi-threaded web server that has great performance on jRuby! If you have added it to your Gemfile, then you can just run it like this:

```bash
$ puma --environment development --port 8000 --threads 0:4
$ puma --environment production --port 80 --threads 32:32
```

## Contributing

Add specs for all new functionality. Run unit tests with RSpec.

```bash
$ bundle exec rspec -fd
```

