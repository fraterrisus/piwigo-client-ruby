# frozen_string_literal: true

# A class that quacks like a File.
class Filelike
  def initialize(filename, data)
    @filename = filename
    @data = data

    match_data = filename.match(/\.([^.]+)\z/)
    @content_type = case match_data[1]
    when 'gif'
      'image/gif'
    when 'jpeg', 'jpg'
      'image/jpeg'
    when 'png'
      'image/png'
    else
      'application/octet-stream'
    end
  end

  def content_type
    @content_type
  end

  def original_filename
    @filename
  end

  def path
    "/#{@filename}"
  end

  def read
    @data
  end

  def to_s
    @data
  end
end
