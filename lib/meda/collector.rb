Dir.glob(File.dirname(File.absolute_path(__FILE__)) + '/collector/*.rb') {|file| require file}

