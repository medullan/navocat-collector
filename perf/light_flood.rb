#!/usr/bin/ruby
# Generate a test plan for each concurrency level given in the arg list
# Example: ruby flood.rb 50 100 200

require 'rubygems'
require 'ruby-jmeter'

HOST = 'aimprod.medullan.com'
PROTOCOL = 'https'
PORT = '443'
TOKEN = 'c6002a7018be11e48c210800200c9a66'

#HOST = 'localhost'
#PROTOCOL = 'http'
#PORT = '9292'
#TOKEN = 'PERF_TOKEN'

LOOPS = 1  #this was orignally 100, should play with this number to see how the perf test responds

loads = ARGV.map {|c| c.to_i }
loads.each do |c|

  test do
    threads :count => c, :loops => LOOPS, :rampup => c, :scheduler => false do

      defaults({
        :domain => HOST, :protocol => PROTOCOL, :port => PORT,
        :connect_timeout => '3000', :response_timeout => '10000'
      })
      header [{:name => 'Content-Type', :value => 'application/json'}]
      
      random_variable :variableName => 'client_id', :minimumValue => 99999999, :maximumValue => 999999999
      random_variable :variableName => 'ip1', :minimumValue => 1, :maximumValue => 127
      random_variable :variableName => 'ip2', :minimumValue => 1, :maximumValue => 127
      random_variable :variableName => 'ip3', :minimumValue => 1, :maximumValue => 127
      random_variable :variableName => 'ip4', :minimumValue => 1, :maximumValue => 127

      # Identify the user by member id, and extract profile_id

      #params = {
      #  :dataset => TOKEN,
      #  :member_id => '${__UUID()}'
      #}
      #post :name => 'IDENTIFY', :url => '/identify.json', :raw_body => params.to_json.to_s, :use_keepalive => 'false' do
      #  extract :name => 'profile_id', :regex => %q{.*"profile_id":"([^"]+)".*}
      #end

      get name: 'meda_home 1', url: '/', :use_keepalive => 'true'

      get name: 'meda_home 2', url: '/', :use_keepalive => 'true'

      10.times do
        get name: 'meda_home 3', url: '/', :use_keepalive => 'true'
      end

      10.times do
        get name: 'meda_other 4', url: '/', :use_keepalive => 'true'
      end


      # Add profile attributes

      params = {
        :dataset => TOKEN,
        :profile_id => '${profile_id}',
        :age => "${__Random(18,100)}",
        :weight => "${__Random(90,200)}",
        :some_long_string_key_1 => "dfskjdhfsdk jfhsd fkjsdhfsdfsdjfhds jfh ksdjfhsdkjfhds fkjdshfk jdhskjdhsd",
        :some_long_string_key_2 => "sdjahskjsahdas kjdhas kjdhsajdhsakjdhas kdhksajd ksaj dksajdhs kajdhks ajdk a",
        :some_long_string_key_3 => "sajdhaksd dahskdjshd  dshjdhs jdhaksdj ahsdkjashdk jsahd hsdjhsk djahsdk asj",
        :some_long_string_key_4 => "asjkdhas djhaskdjsa kjdhsdsjdhsjdhs dsdhasjdhasjd sdhkasjdhksajdhasd sjds aj",
        :some_long_string_key_5 => "dsfjkdshf jdshfjdshfkjdshf sdfhjdshf dksjf sdfhsdjfhskdjfh sdfhsdjfhdks fj ds",
        :some_long_string_key_6 => "sdhf djsfhdjfhdsjfhd kfjsdhfjdshfjd fsdjhfd sjfhdskf sdjfhsdjf sdkfdsjfkdsjfdsj",
        :some_long_string_key_7 => "sdkfjhdsfdsfhdsf dshfdsfhdsfds fksjdfhsdjfdsk fksjd fksdjfhds fdfsdk skdjfhsd",
        :some_long_string_key_8 => "sdkjfdsfdsfdsf sdkfhdsfdsfdsf dshf kdsfkdsfdfdfsd fdfdjfhjsdkfjshkdf sdfskdjfks"
      }
      #post :name => 'PROFILE', :url => '/profile.json', :raw_body => params.to_json.to_s, :use_keepalive => 'false'



    end
  end.run(
    debug: true,
    file: "perf/results/perf_test_#{c}.jmx",
    log: "perf/results/perf_test_#{c}_results.log",
    jtl: "perf/results/perf_test_#{c}_results.jtl"
  )

end

