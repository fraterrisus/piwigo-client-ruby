# frozen_string_literal: true

require 'optparse'

require_relative './file_list_builder'

# Build an OptionParser to parse the command line; then extract the list of files from it.
class PiwigoOptionParser
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
      build_file_list(command_line)
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

  def build_file_list(command_line)
    @files = FileListBuilder.new(files: command_line, recurse: options.recurse).build
  end
end
