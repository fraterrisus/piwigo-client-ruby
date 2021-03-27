# frozen_string_literal: true

require_relative 'requests/base_request'
require_relative 'requests/authenticated_request'

require_relative 'requests/check_session_status'
require_relative 'requests/create_session'
require_relative 'requests/upload_image_chunk'

# Client class for interacting with a Piwigo installation.
class PiwigoClient
  require 'logger'

  attr_accessor :pwg_id

  def initialize(base_uri:, username:, password:)
    @base_uri = base_uri
    @username = username
    @password = password

    @logger = Logger.new($stderr)
  end

  def login
    opts = basic_options.merge({ username: username, password: password })
    req = Requests::CreateSession.new(**opts).run
    @pwg_id = req.pwg_id
    nil
  end

  def check_session_status
    req = Requests::CheckSessionStatus.new(**basic_options).run
    @pwg_token = req.pwg_token
    @chunk_size = req.chunk_size * 1000
    true
  end

  def upload_file(filename, category_id)
    puts "Reading #{filename}"

    image_filename = File.basename(filename)
    image_extension = filename.match(/\.[^.]+\z/).to_s

    file_chunks = get_file_chunks(filename)
    file_chunks.each_with_index do |chunk_data, idx|
      puts "Uploading chunk #{idx + 1} of #{file_chunks.length}"
      chunk_filename = "/tmp/piwigo_upload_data#{image_extension}"
      File.write(chunk_filename, chunk_data)
      upload_chunk(image_filename, category_id, chunk_filename, idx, file_chunks.length)
      File.unlink(chunk_filename)
    end
  end

  private

  attr_reader :base_uri, :chunk_size, :logger, :password, :pwg_token, :username

  def basic_options
    {}.tap do |opts|
      opts[:base_uri] = base_uri
      opts[:cookies] = { pwg_id: pwg_id } if pwg_id
      opts[:logger] = logger
      opts[:logger_level] = :debug
    end
  end

  def get_file_chunks(filename)
    [].tap do |chunks|
      File.open(filename) do |f|
        chunks << f.read(chunk_size) until f.eof?
      end
    end
  end

  def upload_chunk(image_filename, category_id, chunk_filename, idx, num_chunks)
    File.open(chunk_filename) do |f|
      opts = basic_options.merge(
        {
          filename: image_filename,
          category_id: category_id,
          chunk_data: f,
          chunk_num: idx,
          max_chunks: num_chunks,
          pwg_token: pwg_token
        }
      )
      Requests::UploadImageChunk.new(**opts).run
    end
  end
end
