module Meda

  #ruby hash implementation profile database
  class HashDbStore
	
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
  end
end

