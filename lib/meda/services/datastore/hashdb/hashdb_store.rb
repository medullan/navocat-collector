module Meda

  #ruby hash implementation profile database
  class HashDbStore
	   attr_reader :hash

   	def initialize(config)
      @hash = {}
    end

    def encode(key,value)
      @hash[key] = value
    end

    def key?(key)
      @hash.key?(key)
    end

    def decode(key)
      @hash[key]
    end

    def delete(key)
      @hash.delete(key)
    end

    def key_size()
      @hash.length
    end
  end

end

