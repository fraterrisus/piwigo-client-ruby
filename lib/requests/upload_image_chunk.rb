# frozen_string_literal: true

module Requests
  # Pushes one chunk (of possibly many) of a new image file to Piwigo.
  # Non-standard Arguments:
  #   :category_id (int) Destination of uploaded file
  #   :chunk_data (File) A File object containing the data to upload. This must be a File in
  #     order to make the multipart form upload work correctly.
  #   :chunk_num (int) Sequence number of this chunk; 0-indexed, so should always be strictly
  #     less than :max_chunks
  #   :filename (string) Name of the file being uploaded
  #   :max_chunks (int) Number of chunks expected for this file
  #   :pwg_token (string) The logged-in user's API token
  class UploadImageChunk < AuthenticatedRequest
    REQUIRED_OPTS = %i[category_id chunk_data chunk_num filename max_chunks pwg_token].freeze

    def initialize(**opts)
      raise_unless_required_opts!(opts, REQUIRED_OPTS)
      super(opts)

      @category_id = opts[:category_id]
      @chunk_data = opts[:chunk_data]
      @chunk_num = opts[:chunk_num]
      @filename = opts[:filename]
      @max_chunks = opts[:max_chunks]
      @pwg_token = opts[:pwg_token]
    end

    def run
      @response = invoke
      handle_errors!
      self
    end

    private

    attr_reader :category_id, :chunk_data, :chunk_num, :filename, :max_chunks, :pwg_token, :response

    def http_verb
      :post
    end

    def httparty_options
      super.merge(multipart: true)
    end

    def piwigo_method
      'pwg.images.upload'
    end

    def request_body
      super.merge(
        {
          chunk: chunk_num,
          chunks: max_chunks,
          category: category_id,
          pwg_token: pwg_token,
          file: chunk_data,
          name: filename
        }
      )
    end

    def handle_errors!
      raise("Upload Chunk request failed (response code #{response.code})") unless response.success?

      begin
        json_body = JSON.parse(response.body)
        raise("Upload Chunk request failed: #{json_body['message']}") unless json_body['stat'] == 'ok'
      rescue JSON::ParserError
        puts response.body
        raise("Upload Chunk request failed (response code #{response.code})")
      end
    end
  end
end
