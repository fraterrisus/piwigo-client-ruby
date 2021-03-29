# frozen_string_literal: true

require 'optparse'

class UploaderOptionParser
  Options = Struct.new(:base_uri, :category, :config, :password, :recurse, :username,
    keyword_init: true)

  attr_reader :files, :options, :parser

  def initialize(command_line)
    @files = []

    @options = Options.new
    options.config = '.piwigo.conf'

    build_parser(command_line)
    # pp options.to_h

    load_options_from_config_file
    # pp options.to_h

    check_for_required_keys
    get_file_data
  end

  def to_s
    parser.to_s
  end

  private

  def build_parser(command_line)
    @parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options] -c category (file | @list)..."

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

      opts.separator ''
      opts.separator 'Specifying files:'
      opts.separator '  List one or more files on the command line after the arguments.'
      opts.separator '  If a filename starts with @, it will be treated as a newline-separated list of files.'
      opts.separator '  Directories will be skipped unless -r is turned on.'
    end

    @parser.parse!(command_line)
  end

  def load_options_from_config_file
    if File.exist?(options.config)
      begin
        file_options = JSON.parse(File.read(options.config)).map { |k, v| [k.to_sym, v] }.to_h
        options_hash = file_options.merge(options.to_h.compact)
        @options = Options.new(**options_hash)
      rescue JSON::ParserError
        puts "Error reading #{options.config}; is it a JSON file?"
      end
    elsif options.config != '.piwigo.conf'
      warn "Config file #{options.config} not found; proceeding without it"
    end
  end

  def check_for_required_keys
    %w[base_uri username password category].each do |key|
      unless options[key]
        $stderr.puts "Error: You must set a value for #{key}"
        puts parser
        exit
      end
    end
  end

  def handle_file_files(raw_list)
    [].tap do |file_list|
      raw_list.each do |filename|
        if filename.start_with?('@')
          file_file = filename[1..]
          unless File.exist?(file_file)
            $stderr.puts "Error: @file #{file_file} not found"
            raise UploaderError
          end
          file_list += File.readlines(file_file).map(&:chomp)
        else
          file_list << filename
        end
      end
    end
  end

  def handle_directories(raw_list, recurse = false)
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
      begin
        [filename, File.stat(filename).size]
      rescue Errno::ENOENT
        errors << filename
      end
    end.to_h

    if errors.any?
      errors.each { |filename| $stderr.puts "Error: couldn't find file #{filename}" }
      raise UploaderError
    end

    file_sizes
  end

  def get_file_data
    file_list = handle_file_files(ARGV)
    file_list = handle_directories(file_list, options.recurse)
    file_data = get_file_sizes(file_list)

    unless file_data.any?
      $stderr.puts "Error: You must specify one or more files to upload."
      raise UploaderError
    end

    @files = file_data
  end
end
