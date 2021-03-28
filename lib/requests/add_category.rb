# frozen_string_literal: true

module Requests
  class AddCategory < AuthenticatedRequest
    REQUIRED_OPTIONS = %i[cat_name]

    attr_reader :new_album_id

    def initialize(**opts)
      raise_unless_required_opts!(opts, REQUIRED_OPTIONS)
      super(opts)

      @cat_name = opts[:cat_name]
      @parent_id = opts[:parent_id] if opts.key? :parent_id
      @privacy = opts[:privacy] if opts.key? :privacy
    end

    private

    attr_reader :cat_name, :parent_id, :privacy

    def http_verb
      :post
    end

    def piwigo_method
      'pwg.categories.add'
    end

    def request_body
      unless privacy.nil? || privacy == 'public' || privacy == 'private'
        raise(ArgumentError, ':privacy can only have the following values: public private')
      end

      private_opts = {
        name: cat_name,
        parent: parent_id,
        comment: nil, # string
        commentable: nil, #boolean
        visible: nil, # boolean
        status: privacy
      }.compact

      super.merge(private_opts)
    end

    def set_variables
      @new_album_id = json_body['result']['id']
    end
  end
end
