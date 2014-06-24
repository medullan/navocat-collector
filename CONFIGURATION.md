# Configuration

This document describes all of the meda configuration options in detail.

## meda.yml

The `meda.yml` file describes application configuration settings for the collector. The following table details all of the acceptable configuration options. The top level keys of the YAML file should correspond to Rack environments. See the example below for details.

<!-- Markdown tables are hairy. Do it HTML -->
<table>
  <tr>
    <th>Field</th>
    <th>Default</th>
    <th>Usage</th>
  </tr>
  <tr>
    <td>disk_pool</td>
    <td>2</td>
    <td>Number of threads to allocate to disk persistence.</td>
  </tr>
  <tr>
    <td>google_analytics_pool</td>
    <td>2</td>
    <td>Number of threads to allocate to google analytics HTTP connections.</td>
  </tr>
  <tr>
    <td>data_path</td>
    <td>"data"</td>
    <td>The path on disk to write the raw analytics data, relative to the project root.</td>
  </tr>
  <tr>
    <td>log_path</td>
    <td>"log/server.log"</td>
    <td>The path on disk to write the application log, relative to the project root, including the filename.</td>
  </tr>
  <tr>
    <td>log_level</td>
    <td>1</td>
    <td>
      0 = DEBUG<br/>
      1 = INFO<br/>
      2 = WARNING<br/>
      3 = ERROR<br/>
    </td>
  </tr>
  <tr>
    <td>mapdb_path</td>
    <td>"db"</td>
    <td>The path on disk to write the profile databases.</td>
  </tr>
</table>

### Example

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

### Meda configuration in config.ru

If you prefer to configure the collector in Ruby, you can also do this is `config.ru`. For example:

```ruby
# config.ru
require 'rubygems'
require 'bundler/setup'
require 'meda'
require 'meda/collector'

Meda.configure do |config|
  config.disk_pool = 4
  config.google_analytics_pool = 16
  config.mapdb_path = 'db'
  config.data_path = 'meda_data'
  config.log_path = 'log/my_log.log'
  config.log_level = 1
end

run Meda::Collector::App
```

## datasets.yml

The dataset configuration file `datasets.yml` defines the buckets into which analytics data is collected, and how that data is treated. The profile data for each dataset is stored in a separate MapDB database, and analytics data is written to a separate path on the filesystem.

The top level keys of the datasets configuration determine the names of each of the datasets.

The following configuration options are valid:

<!-- Markdown tables are hairy. Do it HTML -->
<table>
  <tr>
    <th>Field</th>
    <th>Usage</th>
  </tr>
  <tr>
    <td>token</td>
    <td>
      The dataset token is included with every analytics request, and indicates which dataset to use. This token is given out to each client integration.
    </td>
  </tr>
  <tr>
    <td>google_analytics -> record</td>
    <td>
      A boolean value indicating whether the hits should also be streamed to google analytics.
    </td>
  </tr>
  <tr>
    <td>google_analytics -> tracking_id</td>
    <td>
      The GA tracking id for the analytics property, of the form UA-XXXXXXX-X. The property must  be a “universal analytics” property.
    </td>
  </tr>
  <tr>
    <td>google_analytics ->
custom_dimensions</td>
    <td>
      A list of the custom dimensions that should be recorded with each google analytics hit. These correspond to recorded user attributes sent with the PROFILE command. The dimensions must be configured in the analytics property, and their indexes must match those in this configuration.
    </td>
  </tr>
</table>

### Example

This file defines three different datasets, each for collecting analytics for three different environments. The production dataset is configured to forward events to GA, while the lower environments are not.

```yaml
# datasets.yml (sample)
production:
  token: afc0a6c8c73211e3aaf844fb42fffe8c
  google_analytics:
    record: true
    tracking_id: UA-1234567-1
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