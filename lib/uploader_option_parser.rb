# frozen_string_literal: true

require 'optparse'

# Build an OptionParser to parse the command line; then extract the list of files from it,
# handling both @file lists as well as recursing into directories.
class UploaderOptionParser
  Options = Struct.new(:base_uri, :category, :config, :create, :password, :recurse, :username,
    keyword_init: true)

  attr_reader :files, :options, :parser

  def initialize(command_line)
    @options = Options.new(config: '.piwigo.conf', create: false, recurse: false)
    @parser = build_parser
    @parser.parse!(command_line)

    begin
      load_options_from_config_file
      check_for_required_keys
      build_file_data
    rescue UploaderError
      puts
      puts @parser
      exit 1
    end
  end

  def to_s
    parser.to_s
  end

  private

  def build_parser
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$PROGRAM_NAME} [options] -c category (file | @list)..."

      opts.separator ''
      docstring = 'Set location of JSON configuration file (default: .piwigo.conf).'
      opts.on('--config FILE', docstring) { |o| options.config = o }
      opts.on('-h', '--help', 'Prints this help') do
        puts opts
        exit
      end

      opts.separator ''
      opts.separator 'Connection options (required):'
      opts.on('-b', '--base_uri HOSTNAME', 'Hostname of Piwigo server') { |o| options.base_uri = o }
      opts.on('-u', '--username USERNAME', 'Username') { |u| options.username = u }
      opts.on('-p', '--password PASSWORD', 'Password') { |p| options.password = p }

      opts.separator ''
      opts.separator 'Image options:'
      docstring = 'Piwigo category to upload files into (required)'
      opts.on('-c', '--category ID', docstring) { |o| options.category = o }
      docstring = 'Recurse into directories (default: off)'
      opts.on('-r', '--recurse', TrueClass, docstring) { |o| options.recurse = o }
      docstring = "Create category by name if it doesn't exist (default: ask)"
      opts.on('--create', TrueClass, docstring) { |o| options.create = o }

      opts.separator ''
      opts.separator 'Specifying files:'
      opts.separator '  List one or more files on the command line after the arguments.'
      opts.separator '  If a filename starts with @, it will be treated as a newline-separated list of files.'
      opts.separator '  Directories will be skipped unless -r is turned on.'
    end
  end

  def load_options_from_config_file
    if File.exist?(options.config)
      begin
        file_options = JSON.parse(File.read(options.config)).transform_keys(&:to_sym)
        options_hash = file_options.merge(options.to_h.compact)
        @options = Options.new(**options_hash)
      rescue JSON::ParserError
        puts "Error reading #{options.config}; is it a JSON file?"
        raise UploaderError
      rescue ArgumentError => e
        puts "Error reading #{options.config}: #{e.message}"
        raise UploaderError
      end
    elsif options.config != '.piwigo.conf'
      warn "Config file #{options.config} not found; proceeding without it"
    end
  end

  def check_for_required_keys
    %w[base_uri username password category].each do |key|
      next if options[key]

      puts "Error: You must set a value for #{key}"
      raise UploaderError
    end
  end

  def handle_file_files(raw_list)
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

  def handle_directories(files:, recurse: false)
    raw_list = files
    [].tap do |file_list|
      until raw_list.empty?
        work_list = raw_list
        raw_list = []
        work_list.each do |filename|
          if File.directory?(filename)
            if recurse
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

  def build_file_data
    file_list = handle_file_files(ARGV)
    file_list = handle_directories(files: file_list, recurse: options.recurse)
    file_data = get_file_sizes(file_list)

    unless file_data.any?
      puts 'Error: You must specify one or more files to upload.'
      raise UploaderError
    end

    @files = file_data
  end
end
