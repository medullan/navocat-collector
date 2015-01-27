#require_relative '../../../collector/spec_helper.rb'
require_relative '../../../../lib/meda/services/datastore/mapdb/mapdb_store'
require_relative '../../../../lib/meda/services/datastore/hashdb/hashdb_store'
require 'tempfile'

describe "datastore" do
	
	key = "key"
	value = "value"

	def encode_and_decode(store,key,value)
		store.encode(key,value)

		result = store.decode(key)
		expect(result).to eq(value)
	end

	def encode_and_key(store,key,value)
		store.encode(key,value)

		result = store.key?(key)
		expect(result).to be_true
	end

	def encode_and_delete(store,key,value)
		store.encode(key,value)

		store.delete(key)
		result = store.key?(key)
		expect(result).to be_false
	end

	describe 'map db store' do

		Meda.configuration.features = {}
		Meda.configuration.features["profile_store"] = "mapdb"

		store_config = {}
		store_config["config"] = Meda.configuration
		store_config["name"] = "testdb_#{rand(10000000)}"

		Meda.featuresNoCache
		
		@profile_store = Meda::ProfileStore.new(store_config)

		store = Meda::MapDbStore.new(store_config)
	    it 'encode and decode' do	   
	    	encode_and_decode(store,key,value)
	    end

	    it 'encode and key' do 
	    	encode_and_key(store,key,value)
	    end

	    it 'encode and delete' do 
	    	encode_and_delete(store,key,value)
	    end
    end

	describe 'hash db store' do
		store = Meda::HashDbStore.new({})
	    it 'encode and decode' do	   
	    	encode_and_decode(store,key,value)
	    end

	    it 'encode and key' do 
	    	encode_and_key(store,key,value)
	    end

	    it 'encode and delete' do 
	    	encode_and_delete(store,key,value)
	    end
    end
end

