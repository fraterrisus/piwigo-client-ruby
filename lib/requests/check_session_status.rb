# frozen_string_literal: true

module Requests
  # Request class to confirm status of auth cookies and get miscellaneous user data
  class CheckSessionStatus < AuthenticatedRequest
    attr_reader :auth_user, :chunk_size, :pwg_token

    private

    attr_reader :json_body, :response

    def piwigo_method
      'pwg.session.getStatus'
    end

    def set_variables
      result = json_body['result']
      @auth_user = result['username']
      @pwg_token = result['pwg_token']
      @chunk_size = result['upload_form_chunk_size']
    end
  end
end
