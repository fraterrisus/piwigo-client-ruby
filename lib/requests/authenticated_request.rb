# frozen_string_literal: true

module Requests
  # Parent class for all requests that manage auth cookies
  class AuthenticatedRequest < BaseRequest
    REQUIRED_OPTIONS = %i[cookies].freeze

    def initialize(**opts)
      super(opts)
      raise_unless_required_opts!(opts, REQUIRED_OPTIONS)
      @cookies = opts[:cookies]
    end

    private

    attr_reader :cookies

    def request_cookies
      super.merge(cookies)
    end
  end
end
