require 'digest'

module Meda
  class Profile

    attr_reader :dataset, :attributes

    def initialize(dataset, attributes={})
      @dataset = dataset
      @attributes = attributes
    end

    def hashed_attributes
      Hash[attributes.map{|k,v| [Digest::SHA1.hexdigest(k), Digest::SHA1.hexdigest(v)]}]
    end

  end
end

