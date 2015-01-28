require_relative 'mapdb.rb'

module Meda

  #map db implementation profile database
  class MapDbStore
	
    attr_reader :mapdb, :path, :tree

   	def initialize(config)
      FileUtils.mkdir_p(config["config"].mapdb_path)
      mapdb_path = File.join(config["config"].mapdb_path, config["name"])
      @mapdb = MapDB::DB.new(mapdb_path.to_s)
      @tree = @mapdb.tree(:meda)
    end

    def encode(key,value)
      @tree.encode(key,value)
    end

    def key?(key)
      @tree.key?(key)
    end

    def decode(key)
      @tree.decode(key)
    end

    def delete(key)
      @tree.delete(key)
    end

    def keys
      @tree.keys
    end

    def key_size
      @tree.size
    end
  end
end

