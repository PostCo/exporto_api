# frozen_string_literal: true

require "open3"
require "rubygems/package"
require "tmpdir"

require_relative "test_helper"

class GemspecTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def test_runtime_dependencies_are_explicit
    dependency_names = specification.runtime_dependencies.map(&:name)

    assert_equal %w[activesupport faraday zeitwerk], dependency_names.sort
    assert specification.required_ruby_version.satisfied_by?(Gem::Version.new("3.3.9"))
  end

  def test_gem_build_contains_runtime_files_and_excludes_project_only_files
    Dir.mktmpdir("exporto-api-gem") do |directory|
      gem_path = File.join(directory, "exporto_api.gem")
      _stdout, stderr, status = Open3.capture3(
        Gem.ruby,
        "-S",
        "gem",
        "build",
        "exporto_api.gemspec",
        "--output",
        gem_path,
        chdir: ROOT
      )

      assert status.success?, stderr

      package = Gem::Package.new(gem_path)
      contents = package.contents
      assert_includes contents, "README.md"
      Dir[File.join(ROOT, "lib/**/*.rb")].each do |file|
        assert_includes contents, file.delete_prefix("#{ROOT}/")
      end
      refute contents.any? { |path| path.start_with?("test/", ".context/", ".github/") }

      extracted_path = File.join(directory, "extracted")
      Dir.mkdir(extracted_path)
      package.extract_files(extracted_path)
      stdout, require_stderr, require_status = Open3.capture3(
        {"BUNDLE_GEMFILE" => nil, "RUBYOPT" => nil},
        Gem.ruby,
        "-I#{File.join(extracted_path, "lib")}",
        "-e",
        <<~RUBY
          require "exporto_api"
          Zeitwerk::Loader.eager_load_all
          abort "Rails was loaded" if defined?(Rails)
          puts $LOADED_FEATURES.find { |feature| feature.end_with?("/lib/exporto_api.rb") }
        RUBY
      )

      assert require_status.success?, require_stderr
      assert_equal(
        File.realpath(File.join(extracted_path, "lib/exporto_api.rb")),
        File.realpath(stdout.strip)
      )
    end
  end

  private

  def specification
    @specification ||= Gem::Specification.load(File.join(ROOT, "exporto_api.gemspec"))
  end
end
