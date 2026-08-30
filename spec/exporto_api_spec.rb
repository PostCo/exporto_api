# frozen_string_literal: true

require "open3"
require "rbconfig"

RSpec.describe ExportoAPI do
  it "has a version number" do
    expect(described_class::VERSION).to eq("0.1.0")
  end

  it "autoloads the Torque-style public constants" do
    expect(described_class::Client).to be_a(Class)
    expect(described_class::Resource).to be_a(Class)
    expect(described_class::Base).to be_a(Class)
    expect(described_class::Error).to be < StandardError
    expect(described_class::Objects).to be_a(Module)
  end

  it "does not expose the unreleased configuration and object APIs" do
    expect(described_class).not_to respond_to(:configure)
    expect(described_class).not_to respond_to(:configuration)
    expect(described_class.const_defined?(:Configuration, false)).to be(false)
    expect(described_class.const_defined?(:Object, false)).to be(false)
  end

  it "loads in a clean Ruby process without Rails or Zeitwerk" do
    script = <<~RUBY
      require "exporto_api"
      abort "Rails loaded" if defined?(Rails)
      abort "Zeitwerk loaded" if defined?(Zeitwerk)
    RUBY

    _stdout, stderr, status = Open3.capture3(
      {"BUNDLE_GEMFILE" => nil, "RUBYOPT" => nil},
      RbConfig.ruby,
      "-I#{File.expand_path("../lib", __dir__)}",
      "-e",
      script
    )

    expect(status).to be_success, stderr
  end
end
