# frozen_string_literal: true

module Requests
  # Request class to logout.
  class DestroySession < BaseRequest
    private

    def piwigo_method
      'pwg.session.logout'
    end
  end
end
