# Medullan Analytics Toolkit

The meda gem currently provides a collector application that is used to gather
analytics events from web browsers, mobile apps or back-end servers.

The collector is written in Sinatra and deployed with the puma webserver.

## Installation

Add this line to your application's Gemfile:

    gem 'meda'

And then execute:

    $ bundle

## Dependencies

The collector application requires ruby 2.0.x or later, and a running redis server, version 2.6.x or later.

## Usage

Add a `config.ru` file to your project to configure the rack environment for the collector.
A sample file may look like this:

```ruby
# config.ru

require 'rubygems'
require 'bundler/setup'
require 'meda'
require 'meda/collector'

Meda.configure do |config|
  config.redis = {
    :host => 'localhost',
    :port => 6379,
    :password => nil
  }
end

run Meda::Collector::App

connection = Meda::Collector::Connection.new
connection.start_disk_streams
connection.start_ga_streams
```

## Run the collector

Puma is a multi-threaded, multi-process web server.
For now, run it with 0-16 threads and a single process (workers).
This command will start a single process with the `config.ru` file.

```
$ puma --port 8000 --threads 0:16 --workers 1
```

## Create datasets

TBD...


