# frozen_string_literal: true

module Requests
  # Fetch the list of categories from the server.
  # Non-standard Arguments:
  #   :tree (boolean, default true) Return data in a tree structure (true) or flat (false)
  class GetCategories < AuthenticatedRequest
    attr_reader :categories

    def initialize(**opts)
      super(opts)

      @tree_output = opts.key?(:tree) ? opts[:tree] : true
    end

    private

    attr_reader :category_id, :tree_output

    def piwigo_method
      'pwg.categories.getList'
    end

    def query_parameters
      super.merge({ recursive: true, tree_output: tree_output })
    end

    def set_variables
      @categories = json_body['result']
      @categories = @categories['categories'] unless tree_output
    end
  end
end
