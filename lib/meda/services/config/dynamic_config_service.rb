require 'psych'
require 'meda'

module Meda
  class DynamicConfigService

    attr_accessor :last_modified_time

    def initialize
      @last_modified_time = File.mtime(Meda::MEDA_CONFIG_FILE)
    end

    def config_changed?
      @curr_modified_time = File.mtime(Meda::MEDA_CONFIG_FILE)
      if @last_modified_time == @curr_modified_time
        return false
      else
        @last_modified_time = @curr_modified_time
        return true
      end
    end

    def update_config(meda_configs)
      new_meda_configs = get_update_configs(meda_configs)
      new_meda_configs
    end

    # TODO make this a util method for sharing among classes
    def get_update_configs(meda_configs)
      begin
        app_configs = Psych.load(File.open(Meda::MEDA_CONFIG_FILE))[ENV['RACK_ENV'] || 'development']
        meda_configs.log_level = app_configs['log_level']
      rescue Errno::ENOENT => error
        puts error
      end
      meda_configs
    end
  end
end