require 'digest'

module Meda
  class Profile

    attr_reader :dataset, :attributes

    def initialize(dataset, attributes={})
      @dataset = dataset
      @attributes = attributes
    end

  end
end

