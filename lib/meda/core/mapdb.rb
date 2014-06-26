require 'java'
require 'forwardable'
require_relative '../../../lib/mapdb-0.9.8.jar'

# Implements a jRuby interface to the embedded MapDB database
module MapDB

  # Represents a MapDB "TreeMap" inside a MapDB database
  class Tree
    extend Forwardable
    attr_reader :tree, :mapdb

    def initialize(name, mapdb)
      @mapdb = mapdb
      @tree = @mapdb.getTreeMap(name.to_s)
    end

    def encode(key, value)
      @tree.put key, Marshal.dump(value).to_java_bytes
    end

    def decode(key)
      stored = @tree.get(key)
      return nil if stored.nil?
      Marshal.load String.from_java_bytes(stored)
    end

    def each
      @tree.each_pair { |key,value| yield(key, Marshal.load(String.from_java_bytes(value))) }
    end

    def keys
      @tree.key_set.to_a
    end

    def regexp(pattern)
      re = Regexp.new "#{pattern}", Regexp::EXTENDED | Regexp::IGNORECASE
      @tree.select{ |k,v| "#{k}" =~ re }.map(&:first)
    end

    def_delegator :@tree, :clear,    :clear
    def_delegator :@tree, :has_key?, :key?
    def_delegator :@tree, :count,    :size
    alias :[]=   :encode
    alias :[]    :decode
    alias :count :size
  end

  # Represents a single database inside MapDB.
  # A DB can be "memory" or "file" type.
  class DB
    extend Forwardable
    attr_reader :mapdb, :type

    # Creates a new MapDB database.
    # If a path is given, then a FileDB will be created at that location.
    # When a path if omitted, a MemoryDB is created.
    def initialize(path=nil)
      if path.nil?
        @type = :MemoryDB
        @mapdb = Java::OrgMapdb::DBMaker.
          newMemoryDB().
          closeOnJvmShutdown().
          make()
      else
        @type = :FileDB
        @mapdb = Java::OrgMapdb::DBMaker.
          newFileDB(Java::JavaIo::File.new("#{path}")).
          closeOnJvmShutdown().
          transactionDisable().
          mmapFileEnable().
          asyncWriteEnable().
          make()
      end
    end

    def tree(treename)
      Tree.new(treename, @mapdb)
    end

    def_delegators :@mapdb, :close, :closed?, :compact
  end
end

