# frozen_string_literal: true

require_relative 'requests/base_request.rb'
require_relative 'requests/authenticated_request.rb'

require_relative 'requests/check_session_status.rb'
require_relative 'requests/create_session.rb'

# Client class for interacting with a Piwigo installation.
class PiwigoClient
  require 'logger'

  def initialize(base_uri:, username:, password:)
    @base_uri = base_uri
    @username = username
    @password = password

    @logger = Logger.new($stderr)

    login
  end

  def check_login_status
    opts = {
      base_uri: base_uri,
      logger: logger,
      logger_level: :debug,
      cookies: cookies
    }
    req = Requests::CheckSessionStatus.new(**opts)
    req.run
  end

  private

  attr_reader :base_uri, :cookies, :logger, :password, :username

  def login
    opts = {
      base_uri: base_uri,
      logger: logger,
      logger_level: :debug,
      username: username,
      password: password
    }
    req = Requests::CreateSession.new(**opts)
    req.run
    @cookies = req.cookies
  end
end
