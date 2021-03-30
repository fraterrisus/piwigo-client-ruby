# frozen_string_literal: true

require_relative 'uploader_error'

# Pulls the list of categories from the server and attempts to match the input string against the
# list of category names.
# - Performs a case-insensitive match.
# - Matches only the whole name, not partial names.
# - Does NOT currently recognize "full names", i.e. category paths with :: as the separator.
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
      print "No matches found for category '#{cat_name}'. Create it (y/N)? "
      if $stdin.gets.chomp.downcase == 'y'
        category_id = client.add_category(cat_name)
        puts "Created category #{category_id} #{cat_name}"
        return category_id
      else
        exit 0
      end
    end

    if matches.count == 1
      category_id = matches.first
      full_name = full_category_name(categories, category_id)
      puts "Uploading to category #{category_id} #{full_name}"
      return category_id
    end

    puts "Multiple matches found for category '#{cat_name}':"
    matches.each do |id|
      full_name = full_category_name(categories, match)
      puts "  (#{id}) #{full_name}"
    end
    raise UploaderError
  end
end
