# frozen_string_literal: true

require "zeitwerk"

module ExportoAPI
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect("exporto_api" => "ExportoAPI")
loader.collapse(File.join(__dir__, "exporto_api", "errors"))
loader.collapse(File.join(__dir__, "exporto_api", "objects"))
loader.collapse(File.join(__dir__, "exporto_api", "resources"))
loader.setup
