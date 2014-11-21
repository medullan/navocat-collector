require 'logger'
require "addressable/uri"

module Meda

  class HitFilter

    attr_accessor :hit, :whitelisted_urls, :google_analytics

    def initialize(google_analytics={})
      @google_analytics = google_analytics
    end

    def filter_hit(hit)
      hit = filter_robot_user(hit)
      hit = filter_age(hit)
      hit = filter_vendor_sites(hit)
      hit = filter_path(hit)
      hit = filter_query_strings(hit)
      hit = filter_profile_data(hit)
    end

    def filter_robot_user(hit)
      begin
        robot_user = hit.props[:robot_user]
        if(robot_user && robot_user=='true')
            hit.tracking_id = 'UA-50799020-3' #Digital Experience Program Stage 
            #hit.props = hit.props.except!(:robot_user)
        end
      rescue StandardError => e
        logger.error("Failure filter robot users: ")
        logger.error(e)
      end
      hit
    end

    def  filter_age(hit)
      begin
        if hit && hit.profile_props and hit.profile_props[:age]
          case hit.profile_props[:age].to_i
          when 1..17
            hit.profile_props[:age]  = '<18'
          when 18..44
            hit.profile_props[:age]  = '18-44'
          when 45..64
            hit.profile_props[:age]  = '45-64'
          else
            hit.profile_props[:age]  = '65+'
          end
        end
      rescue StandardError => e
          logger.error("Can't covert age with value #{hit.profile_props[:age]} to integer")
          logger.error(e)
      end
      hit
    end

    def filter_path(hit)  
      begin
        original_path = hit.props[:path]
        myUri = Addressable::URI.parse(original_path)
        idx = original_path.index(myUri.path)
        hit.props[:path] = original_path[idx..original_path.length-1]
      rescue Addressable::URI::InvalidURIError => e
        logger.error("InvalidURIError cleaning path: #{original_path}")
        logger.error(e)
      rescue TypeError => e
        logger.error("Weird TypeError cleaning path: #{original_path} ")
        logger.error(e)
      rescue ArgumentError => e
        logger.error("Weird ArgumentError cleaning path: #{original_path} ")
        logger.error(e)
      rescue StandardError => e
        logger.error("StandardError cleaning path: #{original_path} ")
        logger.error(e)
      end
      hit
    end


    def filter_vendor_sites(hit)
      begin
        vendor = ""
        url = hit.props[:path].downcase
        if url.include? '/pilot'
          vendor = "MyBlue Pilot - "
        elsif url.include? 'myblue'
          vendor = "MyBlue Classic - "
        elsif url.include? 'custservpt'
          vendor = "EService - "
        elsif url.include? 'mychiprewards'
          vendor = "Chip Rewards - "
        elsif url.include? 'webmd'
          vendor = "WebMD - "
        elsif url.include? 'fepblue.org'
          vendor = "Public Site - "
        end
        hit.props[:title] = vendor.concat(hit.props[:title])
      rescue StandardError => e
          logger.error("Can't determine what partner vendor sites this request comes from")
          logger.error(e)
      end
      hit
    end 


    def filter_query_strings(hit)
      begin
        if hit && hit.props && hit.props[:path] && whitelisted_urls
          current_path = hit.props[:path]
          if current_path.include? "?"
            regex_of_paths = Regexp.union(whitelisted_urls)
            if (!regex_of_paths.match(current_path))
              hit.props[:path] = current_path[0..(current_path.index("?")-1)]
            end
          end
        end

      rescue StandardError => e
        logger.error("Failure cleaning path: ")
        logger.error(e)
      end

      hit
    end

    def filter_profile_data(hit)
      begin
        if !!google_analytics && !!google_analytics['record'] && hit.profile_props
          google_analytics['custom_dimensions'].each_pair do |dimensionName, dimensionConfiguration| 
            filter_profile_data_property(hit.profile_props, dimensionName, dimensionConfiguration['mapping']) 
          end
        end
      rescue StandardError => e
        logger.error("Failure cleaning path: ")
        logger.error(e)
      end

      hit
    end

    def filter_profile_data_property(profile_props, key, mappings)
      begin
        if profile_props[key] and mappings
          value_to_map = profile_props[key]
          profile_props[key] = mappings[value_to_map]
        end
      rescue StandardError => e
        logger.error("Failure filtering #{name} ")
        logger.error(e)
      end
    end

    protected
      def logger
        @logger ||= Meda.logger || Logger.new(STDOUT)
      end
    end
end
