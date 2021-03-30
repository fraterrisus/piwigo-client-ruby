# frozen_string_literal: true

require_relative 'requests/base_request'
require_relative 'requests/authenticated_request'

require_relative 'requests/add_category'
require_relative 'requests/check_session_status'
require_relative 'requests/create_session'
require_relative 'requests/destroy_session'
require_relative 'requests/get_categories'
require_relative 'requests/upload_image_chunk'

require_relative './filelike'

# Client class for interacting with a Piwigo installation.
class PiwigoClient
  require 'logger'

  attr_accessor :chunk_size, :pwg_id

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

  def logout
    Requests::DestroySession.new(**basic_options).run
    @pwg_id = nil
    @pwg_token = nil
    nil
  end

  def add_category(name, parent_id = nil, privacy = nil)
    opts = basic_options.merge(cat_name: name, parent_id: parent_id, privacy: privacy).compact
    req = Requests::AddCategory.new(**opts).run
    req.new_album_id
  end

  def get_categories(tree = nil)
    opts = basic_options.merge({ tree: tree }.compact)
    req = Requests::GetCategories.new(**opts).run
    req.categories
  end

  def upload_file(filename, category_id, progress_bar = nil)
    image_filename = File.basename(filename)
    chunks = split_file(filename)
    chunks.each_with_index do |chunk_data, idx|
      chunk_file = Filelike.new(image_filename, chunk_data)
      upload_chunk(image_filename, category_id, chunk_file, idx, chunks.length)
      progress_bar&.increment!(chunk_data.length)
    end
  end

  private

  attr_reader :base_uri, :logger, :password, :pwg_token, :username

  def basic_options
    {}.tap do |opts|
      opts[:base_uri] = base_uri
      opts[:cookies] = { pwg_id: pwg_id } if pwg_id
      opts[:logger] = logger
      opts[:logger_level] = :debug
    end
  end

  def split_file(filename)
    [].tap do |chunks|
      File.open(filename) do |f|
        chunks << f.read(chunk_size) until f.eof?
      end
    end
  end

  def upload_chunk(image_filename, category_id, chunk_file, idx, num_chunks)
    opts = basic_options.merge(
      {
        filename: image_filename,
        category_id: category_id,
        chunk_data: chunk_file,
        chunk_num: idx,
        max_chunks: num_chunks,
        pwg_token: pwg_token
      }
    )
    Requests::UploadImageChunk.new(**opts).run
  end
end
