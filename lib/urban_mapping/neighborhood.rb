require 'net/http'
require 'uri'

module UrbanMapping
  HOST = 'http://api0.urbanmapping.com'

  class Neighborhood
    BASE_PATH = '/neighborhoods/rest/'

    cattr_accessor :api_key

    class << self
      def search_by_lat_and_lng(lat, lng)
        response = call_api_method('getNearestNeighborhood', :lat => lat, :lng => lng, :api_key => api_key)

        hash_from_xml = hash_from(response)['result']

        if not hash_from_xml['neighborhoods'].blank? and not hash_from_xml['neighborhoods']['neighborhood'].blank?
          {'neighborhoods' => [hash_from_xml['neighborhoods']['neighborhood']].flatten.inject([]) {|arr,hsh| arr << {'name' => hsh['name'].to_s.strip}}}
        else
          {'neighborhoods' => []}
        end
      end

      private
      def hash_from(response)
        # this can be higher performance by using REXML or libxml
        Hash.from_xml response
      end

      def fetch(uri, limit = 10)
        raise ArgumentError, 'HTTP redirect too deep' if limit == 0

        response = Net::HTTP.get_response(URI.parse(uri))

        case response
        when Net::HTTPSuccess
          response
        when Net::HTTPRedirection
          fetch(response['location'], limit - 1)
        else
          response.error!
        end
      end

      def call_api_method(method_name, params = {})
        params['apikey'] ||= api_key
        params['format'] ||= 'xml'

        query_string = params.collect {|k,v| "#{k}=#{v}"}.join('&')

        fetch(File.join(UrbanMapping::HOST, BASE_PATH, method_name) + '?' + query_string).body
      end
    end
  end
end
