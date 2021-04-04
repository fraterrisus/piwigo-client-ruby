# frozen_string_literal: true

require 'optparse'

require_relative 'file_list_builder'
require_relative 'piwigo_options'
require_relative 'uploader_error'

# Build an OptionParser to parse the command line; then extract the list of files from it.
class PiwigoOptionParser
  attr_reader :config, :files, :options, :parser

  def initialize(command_line)
    @config = '.piwigo.conf'
    @options = PiwigoOptions.new
    @parser = build_parser
    @parser.parse!(command_line)

    begin
      load_options_from_config_file
      check_for_required_keys
      return if options.list_categories
      build_file_list(command_line)
    rescue UploaderError => e
      puts e.message
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

      docstring = 'The value of the PWG_ID cookie'
      opts.on('-a', '--authorization TOKEN', docstring) { |a| options.authorization = a }

      docstring = 'Piwigo URL (default: "http://localhost")'
      opts.on('-b', '--base-uri HOSTNAME', docstring) { |o| options.base_uri = o }

      docstring = 'Piwigo category to upload files into (see CATEGORIES)'
      opts.on('-c', '--category ID', docstring) { |o| options.category = o }

      docstring = 'Set location of JSON configuration file (default: .piwigo.conf).'
      opts.on('--config FILE', docstring) { |o| @config = o }

      docstring = "Create category by name if it doesn't exist (default: ask)"
      opts.on('--create', TrueClass, docstring) { |o| options.create = o }

      opts.on('-h', '--help', 'Prints some helpful information about using this script') do
        puts opts
        puts <<-EOF

AUTHORIZATION
  You must either set --username and --password, or --authorization with the value of the PWG_ID
  cookie from a previous login session. If the saved cookie doesn't work, the script will attempt
  to fall back to logging in with username and password. 

  We strongly recommend writing these values to a config file and using --config (or the default,
  .piwigo.conf) rather than specifying them on the command line. Setting --save-auth will write
  the PWG_ID token to the (existing) config file at the end of the run so that the token can be
  read in next time.

CATEGORIES
  You must set --category with either a numeric category ID or a string. In the latter case, the
  script will attempt to match an existing category name. Matches are whole-string, case-insensitive
  (i.e. no partial matches). If no matching categories are found, you will be prompted to create the
  category instead (unless --create, in which case creation happens without prompting).

FILES
  List one or files on the command line after the arguments. If a filename starts with @ it will be
  treated as a newline-separated list of files. Directories will be skipped unless --recurse.

CONFIG FILE
  Configuration may be written to a config file in JSON format. By default the script looks for
  its config in .piwigo.conf in the local directory. Command line options may be stored in the
  config file by their long option name, i.e. "username", "password", "base-uri".
        EOF
        exit
      end

      docstring = "List categories by ID and name; don't upload anything"
      opts.on('-l', '--list-categories', TrueClass, docstring) { |o| options.list_categories = o }

      docstring = "Create category as child of --category"
      opts.on('-n', '--new-category NAME', docstring) { |o| options.new_category = o }

      opts.on('-p', '--password PASSWORD', 'Password') { |p| options.password = p }

      docstring = 'Save session to config file'
      opts.on('--save-auth', TrueClass, docstring) { |p| options.persist_auth = p }

      docstring = 'Recurse into directories (default: off)'
      opts.on('-r', '--recurse', TrueClass, docstring) { |o| options.recurse = o }

      opts.on('-u', '--username USERNAME', 'Username') { |u| options.username = u }
    end
  end

  def load_options_from_config_file
    json = PiwigoOptions.read_config_file(@config)
    @options.apply_defaults(json)
  end

  def check_for_required_keys
    unless (options.username && options.password) || options.authorization
      raise(UploaderError, "Error: You must set a username and password")
    end

    unless options.category || options.list_categories
      raise(UploaderError, "Error: You must set a value for category")
    end
  end

  def build_file_list(command_line)
    @files = FileListBuilder.new(files: command_line, recurse: options.recurse).build
  end
end
