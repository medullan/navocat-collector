require 'rspec'
require 'rr'
require 'webmock/rspec'
require 'rack/test'

puts 'Loading meda'
require 'meda'


module Meda
  describe "Configuration Setup" do
    it 'it loads config from meda.yml' do
      expect(MEDA_CONFIG_FILE).to eq('meda.yml')
    end

    it 'it loads dataset config from datasets.yml' do
      expect(DATASETS_CONFIG_FILE).to eq('datasets.yml')
    end

    it 'it loads no filters if filter class is not in dataset config' do
      dataset = Meda::Dataset.new("test_#{rand(100000)}", Meda.configuration)
      dataset.filter_file_name = "yourfilter2.rb"
      Meda::configure_custom_filter(dataset)
      expect( dataset.hit_filter).to be_nil 
    end

   it 'it loads no filters if filter file is not in dataset config' do
      dataset = Meda::Dataset.new("test_#{rand(100000)}", Meda.configuration)
      dataset.filter_class_name = "YourFilter"
      Meda::configure_custom_filter(dataset)
        expect( dataset.hit_filter).to be_nil 
    end

    xit 'it loads filters if filter name and filter class name is in config' do
      dataset = Meda::Dataset.new("test_#{rand(100000)}", Meda.configuration)
      dataset.filter_file_name = "yourfilter.rb"
      dataset.filter_class_name = "YourFilter"
      Meda::configure_custom_filter(dataset)
      expect( dataset.hit_filter.class.name).to eq(dataset.filter_class_name)
    end

     it 'it fails to load filter if class name is not in rb file' do
      dataset = Meda::Dataset.new("test_#{rand(100000)}", Meda.configuration)
      dataset.filter_file_name = "yourfilter.rb"
      dataset.filter_class_name = "YourFilter2"
      
      expect { Meda::configure_custom_filter(dataset) }.to raise_error

    end
  end
end

