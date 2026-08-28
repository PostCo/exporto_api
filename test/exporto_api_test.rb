# frozen_string_literal: true

require "open3"
require "rbconfig"

require_relative "test_helper"

class ExportoAPITest < Minitest::Test
  def test_namespace_loads_and_all_files_eager_load
    assert_equal "0.1.0", ExportoAPI::VERSION

    Zeitwerk::Loader.eager_load_all

    assert ExportoAPI::Client
    assert ExportoAPI::ConfigurationError < ExportoAPI::Error
  end

  def test_requiring_the_gem_does_not_load_rails
    script = <<~RUBY
      require "exporto_api"
      Zeitwerk::Loader.eager_load_all
      abort "Rails was loaded" if defined?(Rails)
    RUBY

    _stdout, stderr, status = Open3.capture3(
      RbConfig.ruby,
      "-I#{File.expand_path("../lib", __dir__)}",
      "-e",
      script
    )

    assert status.success?, stderr
  end

  def test_exposes_a_configurable_default_configuration
    original = ExportoAPI.configuration
    replacement = ExportoAPI::Configuration.new
    ExportoAPI.configuration = replacement

    ExportoAPI.configure do |configuration|
      configuration.base_url = "https://live.example.test/v1"
    end

    assert_same replacement, ExportoAPI.configuration
    assert_equal "https://live.example.test/v1/", ExportoAPI.configuration.base_url
  ensure
    ExportoAPI.configuration = original
  end
end
