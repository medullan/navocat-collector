require 'java'
require 'logger'
#require 'jdbc/h2'
require 'meda'


require_relative '../../../h2-1.3.176.jar'
require_relative "../../../javassist-3.19.0-GA.jar"
require_relative "../../../slf4j-api-1.7.10.jar"
require_relative "../../../slf4j-simple-1.7.10.jar"
require_relative "../../../HikariCP-2.3.0.jar"
#require_relative "h2_connection_pool_service.rb"


java_import java.sql.DriverManager
java_import java.sql.PreparedStatement
java_import java.sql.Connection


#Jdbc::H2.load_driver(:require) if Jdbc::H2.respond_to?(:load_driver)

module Meda

  class H2ProfileDataAccessService

    attr_reader :db_conn_url

  	def initialize(db_conn_url)
    		DriverManager.register_driver(org.h2.Driver.new)
        @db_conn_url = db_conn_url

    		#@db_conn_pool = Meda::H2ConnectionPoolService.new

        # @h2_thread_pool = Meda::WorkerPool.new({
        #   :size => 200,
        #   :name => "h2_thread_pool"
        # })

        # at_exit do
        #   @h2_thread_pool.shutdown
        # end
  	end

    def createOrUpdateProfile(profile_id, profile_params)
      begin
          profile = getProfile(profile_id)
          if(!profile)
            addProfile(profile_id)
          else
            updateProfile(profile_id, profile_params)
          end
      rescue Exception => error
        puts "!! ERROR UPDATING PROFILE !! -- #{error.message} -- #{error.backtrace}"
        return false 
      end    
    end


    def updateProfile(profile_id, profile_params)
      begin
          #connection = DriverManager.get_connection("jdbc:h2:~/test;USER=sa;PASSWORD=")
          connection = DriverManager.get_connection(@db_conn_url)
          preparedStatement = connection.prepareStatement("UPDATE Profiles SET age=?, gender=?, memberType=?, Option=?, heathAndConsumerSegmentation=?, healthSegmentation=?, consumerSegmentation=? WHERE profile_id=?")
          preparedStatement.setString(1, profile_params[:age] || "") 
          preparedStatement.setString(2, profile_params[:gender] || "")
          preparedStatement.setString(3, profile_params[:memberType] || "")
          preparedStatement.setString(4, profile_params[:Option] || "")
          preparedStatement.setString(5, profile_params[:heathAndConsumerSegmentation] || "")
          preparedStatement.setString(6, profile_params[:healthSegmentation] || "")
          preparedStatement.setString(7, profile_params[:consumerSegmentation] || "")
          preparedStatement.setString(8, profile_id)
          preparedStatement.executeUpdate()
          preparedStatement.close()
          connection.close()        
          return true 
      rescue Exception => error
        puts "!! ERROR UPDATING PROFILE !! -- #{error.message} -- #{error.backtrace}"
        return false 
      end    
    end


  	def addProfile(profile_id)
  		begin
          #connection = DriverManager.get_connection("jdbc:h2:~/test;USER=sa;PASSWORD=")
    			connection = DriverManager.get_connection(@db_conn_url)
          preparedStatement = connection.prepareStatement("INSERT INTO Profiles(profile_id) VALUES (?)")
    			preparedStatement.setString(1, profile_id)
    	    preparedStatement.executeUpdate()
    	    preparedStatement.close()
    			connection.close()  
          return true	
  		rescue Exception => error
   			puts "!! ERROR ADDING PROFILE !! -- #{error.message} -- #{error.backtrace}"
        return false 
  		end  
  	end


    def getProfile(profile_id)
      begin 
          #connection = DriverManager.get_connection("jdbc:h2:~/test;USER=sa;PASSWORD=")
          connection = DriverManager.get_connection(@db_conn_url)
          preparedStatement = connection.prepareStatement("SELECT * FROM Profiles WHERE profile_id=?")  
          preparedStatement.setString(1, profile_id)   
          resultSet = preparedStatement.executeQuery()

          if(!resultSet.isBeforeFirst())
            return false
          end

          while (resultSet.next()) 
            age                            = resultSet.getString("age")
            gender                         = resultSet.getString("gender")
            memberType                     = resultSet.getString("memberType")
            opt                            = resultSet.getString("Option")
            heathAndConsumerSegmentation   = resultSet.getString("heathAndConsumerSegmentation")
            healthSegmentation             = resultSet.getString("healthSegmentation")
            consumerSegmentation           = resultSet.getString("consumerSegmentation")
          end

          preparedStatement.close()
          connection.close()  

          profile = ActiveSupport::HashWithIndifferentAccess.new({
            :id => profile_id,
            :age => age,
            :gender => gender,
            :memberType => memberType,
            :Option => opt,
            :heathAndConsumerSegmentation => heathAndConsumerSegmentation,
            :healthSegmentation => healthSegmentation,
            :consumerSegmentation => consumerSegmentation
          })  

      rescue Exception => error
        puts "!! ERROR READING PROFILE !! -- #{error.message} -- #{error.backtrace}"
        return false 
      end  
    end

    def removeProfile(profile_id)
      begin
          #connection = DriverManager.get_connection("jdbc:h2:~/test;USER=sa;PASSWORD=")
          connection = DriverManager.get_connection(@db_conn_url)
          preparedStatement = connection.prepareStatement("DELETE FROM Profiles WHERE profile_id (?)")
          preparedStatement.setString(1, profile_id)
          preparedStatement.executeUpdate()
          preparedStatement.close()
          connection.close()  
          return true 
      rescue Exception => error
        puts "!! ERROR ADDING PROFILE !! -- #{error.message} -- #{error.backtrace}"
        return false 
      end  
    end


    def addProfile(profile_id)
      begin
          #connection = DriverManager.get_connection("jdbc:h2:~/test;USER=sa;PASSWORD=")
          connection = DriverManager.get_connection(@db_conn_url)
          preparedStatement = connection.prepareStatement("INSERT INTO Profiles(profile_id) VALUES (?)")
          preparedStatement.setString(1, profile_id)
          preparedStatement.executeUpdate()
          preparedStatement.close()
          connection.close()  
          return true 
      rescue Exception => error
        puts "!! ERROR ADDING PROFILE !! -- #{error.message} -- #{error.backtrace}"
        return false 
      end  
    end

    def addProfileLookup(lookup_key, lookup_value)
      begin
          #connection = DriverManager.get_connection("jdbc:h2:~/test;USER=sa;PASSWORD=")
          connection = DriverManager.get_connection(@db_conn_url)
          preparedStatement = connection.prepareStatement("INSERT INTO ProfileLookups(lookup_key, profile_id) VALUES (?, ?)")
          preparedStatement.setString(1, lookup_key)
          preparedStatement.setString(2, lookup_value)
          preparedStatement.executeUpdate()
          preparedStatement.close()
          connection.close()  
          return true 
      rescue Exception => error
        puts "!! ERROR ADDING PROFILE !! -- #{error.message} -- #{error.backtrace}"
        return false 
      end  
    end


    def lookupProfile(lookup_key)
      begin 
          #connection = DriverManager.get_connection("jdbc:h2:~/test;USER=sa;PASSWORD=")
          connection = DriverManager.get_connection(@db_conn_url)
          preparedStatement = connection.prepareStatement("SELECT * FROM ProfileLookups WHERE lookup_key=?")  
          preparedStatement.setString(1, lookup_key)   
          resultSet = preparedStatement.executeQuery()

          if(!resultSet.isBeforeFirst())
            return false
          end

          while (resultSet.next()) 
            lookUpKey                            = resultSet.getString("lookup_key")
            profile_id                          = resultSet.getString("profile_id")
          end

          preparedStatement.close()
          connection.close()  

          profile = ActiveSupport::HashWithIndifferentAccess.new({
            :lookup_key => lookUpKey,
            :profile_id => profile_id
          })  

      rescue Exception => error
        puts "!! ERROR READING PROFILE !! -- #{error.message} -- #{error.backtrace}"
        return false 
      end  
    end





  end
end