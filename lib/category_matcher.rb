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

  def lookup(options)
    cat_id = if options.list_categories
      list_categories
      -1
    elsif options.category.match(/\A\d+\z/)
      options.category.to_i
    else
      convert_category(options.category, options.create)
    end

    if options.new_category
      client.add_category(name: options.new_category, parent_id: cat_id)
      puts "Created category #{category_id} #{cat_name} as child of category #{cat_id}"
      -1
    else
      cat_id
    end
  end

  private

  attr_reader :client

  def full_category_name(categories, id)
    parent_ids = categories[id]['uppercats'].split(',').map(&:to_i)
    parent_ids.map { |parent_id| categories[parent_id]['name'] }.join('::')
  end

  def convert_category(cat_name, autocreate)
    categories = client.get_categories(tree: false).map { |c| [c['id'], c] }.to_h
    matches = categories.keys.select { |id| categories[id]['name'].casecmp(cat_name).zero? }

    unless matches.any?
      print "No matches found for category '#{cat_name}'. Create it (y/N)? " unless autocreate
      if autocreate || $stdin.gets.chomp.downcase == 'y'
        category_id = client.add_category(name: cat_name)
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

  def print_category(category, level = 0)
    print "  " * level
    puts "[#{category['id']}] #{category['name']}"
    category['sub_categories']&.each do |subcat|
      print_category(subcat, level + 1)
    end
  end

  def list_categories
    client.get_categories(tree: true).each do |category|
      print_category(category)
    end
  end
end
