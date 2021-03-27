# frozen_string_literal: true

module Requests
  # Parent class for all Piwigo requests.
  class BaseRequest
    require 'httparty'
    include HTTParty

    ENDPOINT = '/ws.php'

    def initialize(**opts)
      self.class.base_uri(opts[:base_uri]) if opts.key?(:base_uri)
      logger_level = opts[:logger_level] || :info
      self.class.logger(opts[:logger], logger_level) if opts.key?(:logger)
    end

    private

    def invoke
      options = {
        headers: request_headers,
        query: query_parameters,
        body: request_body
      }
      self.class.send(http_verb, ENDPOINT, options)
    end

    def http_verb
      :post
    end

    def raise_unless_required_opts!(opts, required)
      required.each do |key|
        raise(ArgumentError, "Missing required argument #{key}") unless opts.key?(key)
      end
    end

    def query_parameters
      {
        format: 'json'
      }
    end

    def piwigo_method
      raise(NoMethodError, 'Request class must implement #piwigo_method')
    end

    def request_body
      {
        method: piwigo_method
      }
    end

    def request_headers
      {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8'
      }
    end
  end
end
