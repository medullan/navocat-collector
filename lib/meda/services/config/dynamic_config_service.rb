require 'psych'
require 'meda'

module Meda
  class DynamicConfigService

    def initialize
      @last_modified_time = File.mtime(Meda::MEDA_CONFIG_FILE)
    end

    def update_config(meda_configs)
      @curr_modified_time = File.mtime(Meda::MEDA_CONFIG_FILE)
      if @last_modified_time == @curr_modified_time
        return meda_configs
      else
        new_meda_configs = get_update_configs(meda_configs)
        @last_modified_time = @curr_modified_time
      end
      new_meda_configs
    end

    def get_update_configs(meda_configs)
      begin
          app_configs = Psych.load(File.open(Meda::MEDA_CONFIG_FILE))[ENV['RACK_ENV'] || 'development']
          temp = app_configs['log_level']
          meda_configs.log_level = temp
            temp2 = meda_configs
      rescue Errno::ENOENT => error
        puts error
      end
      meda_configs
    end
  end
end