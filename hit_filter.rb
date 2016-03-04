require 'logger'
require "addressable/uri"

require 'ipaddr'

class CustomHitFilter

  attr_accessor :hit, :google_analytics, :full_path

  def filter_hit(hit, dataset)
    if(dataset)
      logger.info("start of hit filter")
      @dataset = dataset
      @google_analytics = dataset.google_analytics
    end

    full_url = hit.props[:path]
    #hit = filter_ip_from_referrer(hit)
    hit = filter_campaign(hit)
    hit = filter_age(hit)
    hit = filter_path(hit)
    hit = filter_profile_data(hit)
  end

  def filter_ip_from_referrer(hit)
    begin
      if(hit && hit.props)

        referrer = hit.props[:referer]
        idx = referrer.index(':')
        referrer = referrer[0..idx-1] if !idx.nil?

        if (!(IPAddr.new(referrer) rescue nil).nil?)
          hit.props[:referer] = ""
        end
      end
    rescue StandardError => e
      logger.error("StandardError filtering referrer: #{referrer} ")
      logger.error(e)
    end
    hit
  end

  def filter_campaign(hit)
    begin
      if(hit.props && hit.props[:path])
        original_path = hit.props[:path]
        myUri = Addressable::URI.parse(original_path)
        query_strings = myUri.query_values
        if(query_strings)
          hit.props[:campaign_name] = query_strings["utm_campaign"] if query_strings.has_key?("utm_campaign")
          hit.props[:campaign_source] = query_strings["utm_source"] if query_strings.has_key?("utm_source")
          hit.props[:campaign_medium] = query_strings["utm_medium"] if query_strings.has_key?("utm_medium")
          hit.props[:campaign_keyword] = query_strings["utm_keyword"] if query_strings.has_key?("utm_keyword")
          hit.props[:campaign_content] = query_strings["utm_content"] if query_strings.has_key?("utm_content")
        end
      end
    rescue Addressable::URI::InvalidURIError => e
      logger.error("InvalidURIError filtering campaign: #{original_path}")
      logger.error(e)
    rescue TypeError => e
      logger.error("Weird TypeError filtering campaign: #{original_path} ")
      logger.error(e)
    rescue ArgumentError => e
      logger.error("Weird ArgumentError filtering campaign: #{original_path} ")
      logger.error(e)
    rescue StandardError => e
      logger.error("StandardError filtering campaign: #{original_path} ")
      logger.error(e)
    end
    hit
  end

  def filter_age(hit)
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
      @full_path = original_path

      if !original_path.downcase.include? "file:"
        myUri = Addressable::URI.parse(original_path)
        idx = original_path.index(myUri.path)
        hit.props[:path] = original_path[idx..original_path.length-1]
      else
        hit.is_invalid = true
      end
    rescue Addressable::URI::InvalidURIError => e
      logger.error("InvalidURIError filtering path: #{original_path}")
      logger.error(e)
    rescue TypeError => e
      logger.error("Weird TypeError filtering path: #{original_path} ")
      logger.error(e)
    rescue ArgumentError => e
      logger.error("Weird ArgumentError filtering path: #{original_path} ")
      logger.error(e)
    rescue StandardError => e
      logger.error("StandardError filtering path: #{original_path} ")
      logger.error(e)
    end
    hit
  end

  def filter_profile_data(hit)
    begin
      if !!google_analytics && !!google_analytics['record'] && hit.profile_props && google_analytics['custom_dimensions']
        google_analytics['custom_dimensions'].each_pair do |dimensionName, dimensionConfiguration|
          filter_profile_data_property(hit.profile_props, dimensionName, dimensionConfiguration['mapping'])
        end
      end
    rescue StandardError => e
      logger.error("Failure mapping profile data ")
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
      logger.error("Failure filtering: #{name} ")
      logger.error(e)
    end
  end

  protected
  def logger
    @logger ||= Meda.logger || Logger.new(STDOUT)
  end
end