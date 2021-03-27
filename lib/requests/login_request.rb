# frozen_string_literal: true

module Requests
  # Request class to perform login and capture auth cookies
  class LoginRequest < Requests::BaseRequest
    REQUIRED_OPTS = %i[username password].freeze

    attr_reader :cookies

    def initialize(**opts)
      raise_unless_required_opts!(opts, REQUIRED_OPTS)
      super(opts)

      @username = opts[:username]
      @password = opts[:password]
    end

    def run
      @response = invoke
      handle_errors!
      set_cookies
    end

    private

    attr_reader :json_body, :password, :response, :username

    def handle_errors!
      raise("Login request failed (response code #{response.code})") unless response.success?

      @json_body = JSON.parse(@response.body)
      raise("Login request failed: #{@json_body['message']}") unless @json_body['stat'] == 'ok'
    end

    def piwigo_method
      'pwg.session.login'
    end

    def request_body
      super.merge(username: username, password: password)
    end

    def set_cookies
      @cookies = {}
      @response.headers.to_h['set-cookie'].each do |raw_cookie|
        key, value = raw_cookie.split('=', 2)
        @cookies[key] = value
      end
    end
  end
end
