# frozen_string_literal: true

module Requests
  class GetCategories < AuthenticatedRequest
    attr_reader :categories

    private

    attr_reader :category_id, :json_body

    def piwigo_method
      'pwg.categories.getList'
    end

    def query_parameters
      super.merge({ recursive: true, tree_output: true })
    end

    def set_variables
      @categories = json_body['result']
    end
  end
end
