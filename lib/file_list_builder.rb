# frozen_string_literal: true

# Builds file lists from a command line (that's been stripped of arguments and options).
# Handles @lists and recursion, if asked nicely.
class FileListBuilder
  def initialize(files:, recurse:)
    @files = files
    @recurse = recurse
  end

  def build
    file_list = handle_file_files
    file_list = handle_directories(file_list)
    file_data = get_file_sizes(file_list)

    unless file_data.any?
      puts 'Error: You must specify one or more files to upload.'
      raise UploaderError
    end

    file_data
  end

  private

  def handle_file_files
    raw_list = @files.dup
    [].tap do |file_list|
      raw_list.each do |filename|
        if filename.start_with?('@')
          file_file = filename[1..]
          unless File.exist?(file_file)
            puts "Error: @file #{file_file} not found"
            raise UploaderError
          end
          file_list += File.readlines(file_file).map(&:chomp)
        else
          file_list << filename
        end
      end
    end
  end

  def handle_directories(raw_list)
    [].tap do |file_list|
      until raw_list.empty?
        work_list = raw_list
        raw_list = []
        work_list.each do |filename|
          if File.directory?(filename)
            if @recurse
              raw_list += Dir.glob("#{filename}/*")
            else
              warn "Skipping directory #{filename}"
            end
          else
            file_list << filename
          end
        end
      end
    end
  end

  def get_file_sizes(file_list)
    errors = []
    file_sizes = file_list.map do |filename|
      [filename, File.stat(filename).size]
    rescue Errno::ENOENT
      errors << filename
    end.to_h

    if errors.any?
      errors.each { |filename| puts "Error: couldn't find file #{filename}" }
      raise UploaderError
    end

    file_sizes
  end
end
