class InvalidationFilter 
    def filter_hit(hit,dataset) 
       hit.is_invalid = true
       hit
    end
end