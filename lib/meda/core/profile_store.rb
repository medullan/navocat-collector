require_relative 'mapdb'
require 'uuidtools'
require 'digest'
require 'logger'

module Meda

  # Implements persistence of profile data into the MapDB
  class ProfileStore

    attr_reader :mapdb, :path, :tree

    def initialize(path)
      @path = path
      @mapdb = MapDB::DB.new(path.to_s)
      @tree = @mapdb.tree(:meda)
    end

    # Create a new profile with the identifying info in the given hash
    def create_profile(info)
      profile_id = UUIDTools::UUID.timestamp_create.hexdigest

      # Create the main record, ie "profile:12341234123412341234124"
      @tree.encode(profile_key(profile_id), {'id' => profile_id})

      # Create lookups for each attribute. ie "profile:lookup:{hashed key}:{hashed val}"
      info.each_pair do |k, v|
        @tree.encode(key_hashed_profile_lookup(k,v), profile_id)
      end
      ActiveSupport::HashWithIndifferentAccess.new({'id' => profile_id})
    end

    # Add additional identifying info in the given hash to an existing profile
    def alias_profile(profile_id, info)
      # Create additional for each alias attribute.
      if @tree.key?(profile_key(profile_id))
        info.each_pair do |k, v|
          @tree.encode(key_hashed_profile_lookup(k,v), profile_id)
        end
        true
      else
        logger.error("alias_profile ==> No profile found with key: #{profile_id}")
        false # no profile
      end
    end

    # Find or create a profile for the identifying info in the given hash
    def find_or_create_profile(info)
      profile_id = lookup_profile(info)
      logger.info("find_or_create_profile ==> Profile ID: #{profile_id}")
      if profile_id
        get_profile_by_id(profile_id)
      else
        create_profile(info)
      end
    end

    # Return a hash with the profile info for the given profile_id
    def get_profile_by_id(profile_id)
      if @tree.key?(profile_key(profile_id))
        ActiveSupport::HashWithIndifferentAccess.new(@tree.decode(profile_key(profile_id)))
      else
        logger.error("get_profile_by_id ==> No profile found with key #{profile_key(profile_id)}")
        false # no profile
      end
    end

    # Set additional attributes on a profile from the given profile_info hash
    def set_profile(profile_id, profile_info)
      if @tree.key?(profile_key(profile_id))
        existing_profile = @tree.decode(profile_key(profile_id))
        @tree.encode(profile_key(profile_id), existing_profile.merge(profile_info))
        true
      else
        logger.error("set_profile ==> No profile found with key #{profile_id}")
        false # no profile
      end
    end

    # delete profile given profile if
    def delete_profile(profile_id)
      if @tree.key?(profile_key(profile_id))
        @tree.delete(profile_key(profile_id))
        true
      else
        logger.error("delete_profile ==> No profile found with key #{profile_id}")
        false # no profile
      end
    end

    # Uses one criteria at a time from the given hash, in order, until a match is found
    def lookup_profile(info)
      lookup_keys = info.map{|k,v| key_hashed_profile_lookup(k,v)}
      logger.info("lookup_profile ==> Lookup keys: #{lookup_keys}")
      while (lookup_keys.length > 0) do
        test_key = lookup_keys.shift
        logger.info("lookup_profile ==> test keys: #{test_key}")
        return @tree.decode(test_key) if @tree.key?(test_key)
      end

          puts "going to send an error"
          puts logger

      logger.error("lookup_profile ==> Nothing found in info: #{info}")
      false
    end

    # TreeMap key for hashed profile lookup key
    def key_hashed_profile_lookup(k,v)
      "profile:lookup:#{Digest::SHA1.hexdigest(k.to_s)}:#{Digest::SHA1.hexdigest(v.to_s)}"
    end

    # TreeMap key for profile data
    def profile_key(id)
      "profile:#{id}"
    end

    def logger
      @logger ||= Meda.logger || Logger.new(STDOUT)
    end

  end
end
