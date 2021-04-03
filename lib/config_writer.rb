# frozen_string_literal: true

require 'json'

require_relative 'piwigo_options'

class ConfigWriter
  def self.update(filename, key, value)
    if File.exist?(filename)
      warn "Updating '#{key}' in config file #{filename}"
      json = PiwigoOptions.read_config_file(filename)
      json[key] = value
      File.write(filename, JSON.pretty_generate(json) + "\n")
    else
      warn "Couldn't find config file #{filename}, won't create it"
    end
  end

  def self.delete(filename, key)
    if File.exist?(filename)
      warn "Deleting '#{key}' from config file #{filename}"
      json = PiwigoOptions.read_config_file(filename)
      json.delete(key.to_s)
      File.write(filename, JSON.pretty_generate(json) + "\n")
    end
  end
end
