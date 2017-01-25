#!/usr/bin/env puma

#This variable determines what config is selected in meda.yml
meda_env = 'production'
environment meda_env
ENV['RACK_ENV'] = meda_env

#daemonize - disabled because it doesn't work on windows

#stdout_redirect 'log/server_stdout.log', 'log/server_stderr.log'
threads 20, 300


#Uncomment below to test locally
bind 'tcp://127.0.0.1:8000'

#Uncomment below for the test environment 
#bind 'tcp://10.50.0.83:80'

#Uncomment below for the stage environment
#bind 'tcp://10.30.0.82:80'

#Uncomment below for the production environment
#bind 'tcp://10.10.0.168:80'

#Uncomment below for medullan aimdev environment
#bind 'tcp://aimpdev.medullan.com:80/'

#Uncomment below for medullan aimprod environment
#bind 'tcp://aimprod.medullan.com:80/'

#N.B. SSL not enabled for above environment as they are accessed through an SSL enabled load balancer

#Below is an example of how you'd configure SSL on the collector iteself.
#You will need to put similar files in this folder to enable ssl on jruby
#bind 'ssl://aimprod.medullan.com:443?keystore=security/meda_prod.ks&key=security/server.key&cert=security/server.crt&keystore-pass=changeit'

