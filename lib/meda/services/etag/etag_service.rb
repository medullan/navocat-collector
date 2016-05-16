require 'logger'
require 'meda'

module Meda
  class EtagService

    def set_etag_profile_id(profile_id, etag_hash)
      if !etag_hash.blank? && !profile_id.blank?
        etag_hash = etag_hash
        etag_hash["profile_id"] = profile_id
        Meda.logger.info("updated etag with profile id #{etag_hash}")
        return etag_hash
      else
        Meda.logger.warn("profile_id or etag_hash is empty")
        return etag_hash
      end
    end

    def set_etag_client_id(client_id, etag_hash)
      if !etag_hash.blank? && !client_id.blank?
        etag_hash = etag_hash
        etag_hash["client_id"] = client_id
        Meda.logger.info("updated etag with client_id #{etag_hash}")
        return etag_hash
      else
        Meda.logger.warn("client_id or etag_hash is empty")
        return etag_hash
      end
    end

    def get_current_etag(request)
      origin_etag = request.env['HTTP_IF_NONE_MATCH'].to_s.clone
      etag = origin_etag.gsub!(/\A"|"\Z/, '')
      if etag.blank?
        new_etag = create_etag_hash
        Meda.logger.info("creating new etag #{new_etag}")
        return new_etag
      end
      Meda.logger.info("etag exist in the HTTP_IF_NONE_MATCH header, returning etag: #{etag}")
      string_to_hash(etag)
    end

    # Accepts a string in the following format
    # "client_id=123;profile_id=321;" and converts
    # it to a ruby hash in the form
    # { "client_id" => 123, "profile_id", 321}
    def string_to_hash(str)
      Hash[
          str.split(';').map do |pair|
            k, v = pair.split('=', 2)
            [k, v]
          end]
    end

    # Convert has in the form
    # { "client_id" => 123, "profile_id", 321}
    # to string "client_id=123;profile_id=321"
    def hash_to_string(hash)
      str = ''
      hash.each do |key, value|
        str << key.to_s + '=' + value.to_s + ';'
      end
      str
    end

    def create_etag_hash
      string_to_hash(create_etag_string)
    end

    def create_etag_string
      etag = "client_id=#{UUIDTools::UUID.random_create.to_s};profile_id=#{" "};"
      return etag
    end

    def get_profile_id_from_etag(params, etag_hash)
      if !etag_hash["profile_id"].blank? || !params[:profile_id].blank?
        return params[:profile_id] ||= etag_hash["profile_id"]
      else
        Meda.logger.warn("tried to get profile_id from params and etag_hash, but it's empty")
        return nil
      end
    end

    def get_client_id_from_etag(params, etag_hash)
      if !etag_hash["client_id"].blank? || !params[:client_id].blank?
        return params[:client_id] ||= etag_hash["client_id"]
      else
        Meda.logger.warn("tried to get client_id from params and etag_hash, but they're empty")
        return nil
      end
    end
  end
end