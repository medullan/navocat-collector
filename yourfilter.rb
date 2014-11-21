
    class YourFilter 

  		attr_accessor :hit, :whitelisted_urls, :google_analytics
		
		def filter_hit(hit,dataset) 
		   puts "-----\nin my filter 12!\n------"
		   hit
		end

  	end
