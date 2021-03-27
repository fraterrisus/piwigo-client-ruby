# frozen_string_literal: true

module Requests
  # Request class to perform login and capture auth cookie
  class CreateSession < BaseRequest
    REQUIRED_OPTS = %i[username password].freeze

    attr_reader :pwg_id

    def initialize(**opts)
      raise_unless_required_opts!(opts, REQUIRED_OPTS)
      super(opts)

      @username = opts[:username]
      @password = opts[:password]
    end

    def run
      @response = invoke
      handle_errors!
      set_variables
      self
    end

    private

    attr_reader :json_body, :password, :response, :username

    def http_verb
      :post
    end

    def piwigo_method
      'pwg.session.login'
    end

    def request_body
      super.merge(username: username, password: password)
    end

    def handle_errors!
      raise("Login request failed (response code #{response.code})") unless response.success?

      @json_body = JSON.parse(@response.body)
      raise("Login request failed: #{@json_body['message']}") unless @json_body['stat'] == 'ok'
    end

    def set_variables
      raw_cookie = @response.headers.to_h['set-cookie'].find { |c| c.start_with?('pwg_id=') }
      return unless raw_cookie

      tokens = raw_cookie.split('=', 2)
      tokens = tokens[1].split(';')
      @pwg_id = tokens[0]
    end
  end
end
