# frozen_string_literal: true

require_relative 'uploader_error'

class PiwigoOptions
  KEYS = %i[authorization base_uri category create list_categories password persist_auth recurse
    username].freeze

  DEFAULTS = {
    base_uri: 'http://localhost',
    create: false,
    persist_auth: false,
    recurse: false
  }.freeze

  attr_accessor(*KEYS)

  def apply_file(filename)
    if File.exist?(filename)
      begin
        file_options = JSON.parse(File.read(filename)).
          transform_keys { |k| k.gsub('-', '_').to_sym }
        apply_defaults(file_options)
      rescue JSON::ParserError
        puts "Error reading #{filename}; is it a JSON file?"
        raise UploaderError
      end
    elsif filename != '.piwigo.conf'
      warn "Config file #{filename} not found; proceeding without it"
    end
  end

  def apply_defaults(others)
    from_h(DEFAULTS.merge(others).merge(to_h.compact))
  end

  def to_s
    to_h.to_s
  end

  def to_h
    KEYS.sort.map { |k| [k, public_send(k)] }.to_h
  end

  def from_h(hash)
    hash.each do |k, v|
      public_send("#{k}=", v) if KEYS.include?(k)
    end
  end

  def self.from_h(hash)
    self.new.tap { |options| options.from_h(hash) }
  end
end
