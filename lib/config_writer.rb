# frozen_string_literal: true

require 'json'

require_relative 'piwigo_options'

class ConfigWriter
  def self.update(filename, key, value)
    # FIXME: file not found error
    json = PiwigoOptions.read_config_file(filename)
    json[key] = value
    File.write(filename, JSON.pretty_generate(json) + "\n")
  end
end
