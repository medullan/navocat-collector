require 'logger'

module Meda

  class HitFilter

    attr_accessor :hit, :google_analytics

    def initialize(google_analytics={})
      @google_analytics = google_analytics
    end

    def filter_hit(hit)
      hit = filter_age(hit)
      hit = filter_query_strings(hit)
      hit = filter_profile_data(hit)
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

    def filter_query_strings(hit)
      begin
        if hit && hit.props && hit.props[:path]
          current_path = hit.props[:path]
          if current_path.include? "?"

            whitelisted_paths = [/\/hra\/lobby\.aspx\?toolid=3563/,/\/web\/guest\/myblue\?.*Fcreate_account$/,/\/web\/guest\/myblue\?.*Fcreate_account&_58_resume=$/]
            regex_of_paths = Regexp.union(whitelisted_paths)

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

        if !!google_analytics && !!google_analytics['record']

          hit = filter_gender(hit)
          hit = filter_member_type(hit)
          hit = filter_option(hit)
          hit = filter_health_and_consumer_segmentation(hit)
          hit = filter_health_segmentation(hit)
          hit = filter_consumer_segmentation(hit)
        end
      rescue StandardError => e
        logger.error("Failure cleaning path: ")
        logger.error(e)
      end
      hit
    end

    def filter_gender(hit)
      begin
        value_to_map = hit.profile_props[:gender]
        hit.profile_props[:gender] = google_analytics['custom_dimensions']['gender']['mapping'][value_to_map]
      rescue StandardError => e
        logger.error("Failure filtering gender ")
        logger.error(e)
      end
      hit
    end

    def filter_member_type(hit)
      begin
        value_to_map = hit.profile_props[:memberType]
        hit.profile_props[:memberType] = google_analytics['custom_dimensions']['memberType']['mapping'][value_to_map]
      rescue StandardError => e
        logger.error("Failure filtering memberType ")
        logger.error(e)
      end
      hit
    end

    def filter_option(hit)
      begin
        value_to_map = hit.profile_props[:Option]
        hit.profile_props[:Option] = google_analytics['custom_dimensions']['Option']['mapping'][value_to_map]
      rescue StandardError => e
        logger.error("Failure filtering Option ")
        logger.error(e)
      end
      hit
    end

    def filter_health_and_consumer_segmentation(hit)
      begin
        value_to_map = hit.profile_props[:healthAndConsumerSegmentation]
        hit.profile_props[:healthAndConsumerSegmentation] = google_analytics['custom_dimensions']['healthAndConsumerSegmentation']['mapping'][value_to_map]
      rescue StandardError => e
        logger.error("Failure filtering healthAndConsumerSegmentation ")
        logger.error(e)
      end
      hit
    end

    def filter_health_segmentation(hit)
      begin
        value_to_map = hit.profile_props[:healthSegmentation]
        hit.profile_props[:healthSegmentation] = google_analytics['custom_dimensions']['healthSegmentation']['mapping'][value_to_map]
      rescue StandardError => e
        logger.error("Failure filtering healthSegmentation ")
        logger.error(e)
      end
      hit
    end

    def filter_consumer_segmentation(hit)
      begin
        value_to_map = hit.profile_props[:consumerSegmentation]
        hit.profile_props[:consumerSegmentation] = google_analytics['custom_dimensions']['consumerSegmentation']['mapping'][value_to_map]
      rescue StandardError => e
        logger.error("Failure filtering consumerSegmentation ")
        logger.error(e)
      end
      hit
    end

    protected
      def logger
        @logger ||= Meda.logger || Logger.new(STDOUT)
      end
    end
end
