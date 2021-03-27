# frozen_string_literal: true

# Client class for interacting with a Piwigo installation.
class PiwigoClient
  Dir.glob(File.join(__dir__, '**', '*.rb')).sort.each(&method(:require))

  require 'logger'

  attr_reader :cookies

  def initialize(base_uri:, username:, password:)
    @base_uri = base_uri
    @username = username
    @password = password

    @logger = Logger.new($stderr)

    login
  end

  private

  attr_reader :base_uri, :logger, :password, :username

  def login
    opts = {
      base_uri: base_uri,
      logger: logger,
      logger_level: :debug,
      username: username,
      password: password
    }
    req = Requests::LoginRequest.new(**opts)
    req.run
    @cookies = req.cookies
  end
end
