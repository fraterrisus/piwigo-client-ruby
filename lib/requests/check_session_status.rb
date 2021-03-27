# frozen_string_literal: true

module Requests
  # Request class to confirm status of auth cookies and get miscellaneous user data
  class CheckSessionStatus < AuthenticatedRequest
    attr_reader :chunk_size, :pwg_token

    def run
      @response = invoke
      handle_errors!
      set_variables
      self
    end

    private

    attr_reader :json_body, :response

    def piwigo_method
      'pwg.session.getStatus'
    end

    def handle_errors!
      raise("Check Session request failed (response code #{response.code})") unless response.success?

      @json_body = JSON.parse(@response.body)
      raise("Check Session request failed: #{@json_body['message']}") unless @json_body['stat'] == 'ok'
    end

    def set_variables
      @pwg_token = json_body['result']['pwg_token']
      @chunk_size = json_body['result']['upload_form_chunk_size']
    end
  end
end
