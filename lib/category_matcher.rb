# frozen_string_literal: true

require_relative 'uploader_error'

class CategoryMatcher
  def initialize(client)
    @client = client
  end

  def lookup(category)
    if category.match(/\A\d+\z/)
      category.to_i
    else
      convert_category(category)
    end
  end

  private

  attr_reader :client

  def full_category_name(categories, id)
    parent_ids = categories[id]['uppercats'].split(',').map(&:to_i)
    parent_ids.map { |parent_id| categories[parent_id]['name'] }.join('::')
  end

  def convert_category(cat_name)
    categories = client.get_categories(false).map { |c| [c['id'], c] }.to_h
    matches = categories.keys.select { |id| categories[id]['name'].casecmp(cat_name).zero? }

    unless matches.any?
      $stderr.puts "No matches found for category '#{cat_name}'"
      raise UploaderError
    end

    if matches.count == 1
      category_id = matches.first
      full_name = full_category_name(categories, category_id)
      $stderr.puts "Uploading to category #{category_id} #{full_name}"
      return category_id
    end

    $stderr.puts "Multiple matches found for category '#{cat_name}':"
    matches.each do |id|
      full_name = full_category_name(categories, match)
      $stderr.puts "  (#{id}) #{full_name}"
    end
    raise UploaderError
  end
end
