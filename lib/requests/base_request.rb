# frozen_string_literal: true

module Requests
  # Parent class for all Piwigo requests.
  class BaseRequest
    require 'httparty'
    include HTTParty

    ENDPOINT = '/ws.php'

    def initialize(**opts)
      self.class.base_uri(opts[:base_uri]) if opts.key?(:base_uri)
      # logger_level = opts[:logger_level] || :info
      # self.class.logger(opts[:logger], logger_level) if opts.key?(:logger)

      # self.class.debug_output($stderr)
    end

    def run
      raise(NoMethodError, 'Request class must implement #run')
    end

    private

    def invoke
      self.class.send(http_verb, ENDPOINT, httparty_options)
    end

    def http_verb
      :get
    end

    def httparty_options
      {
        headers: request_headers,
        query: query_parameters,
        body: request_body
      }
    end

    def raise_unless_required_opts!(opts, required)
      required.each do |key|
        raise(ArgumentError, "Missing required argument #{key}") unless opts.key?(key)
      end
    end

    def query_parameters
      {}.tap do |params|
        params['format'] = 'json'
        params['method'] = piwigo_method if http_verb == :get
      end
    end

    def piwigo_method
      raise(NoMethodError, 'Request class must implement #piwigo_method')
    end

    def request_body
      {}.tap do |params|
        params['method'] = piwigo_method if http_verb == :post
      end
    end

    def request_cookies
      {}
    end

    def request_headers
      {}.tap do |headers|
        headers['Accept'] = 'application/json'
        headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=utf-8'

        cookies = request_cookies.map { |k, v| "#{k}=#{v}" }.join('; ')
        headers['Cookie'] = cookies unless cookies.empty?
      end
    end
  end
end
