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

    private

    attr_reader :password, :username

    def http_verb
      :post
    end

    def piwigo_method
      'pwg.session.login'
    end

    def request_body
      super.merge(username: username, password: password)
    end

    def set_variables
      raw_cookie = response.headers.to_h['set-cookie'].select { |c| c.start_with?('pwg_id=') }.last
      return unless raw_cookie

      tokens = raw_cookie.split('=', 2)
      tokens = tokens[1].split(';')
      @pwg_id = tokens[0]
    end
  end
end
