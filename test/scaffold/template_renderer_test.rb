# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "stringio"
require "ratatui_ruby/devtools/scaffold/scaffold_config"
require "ratatui_ruby/devtools/scaffold/template_renderer"
require "ratatui_ruby/devtools/tasks/bump/changelog"
require "ratatui_ruby/devtools/tasks/bump/sem_ver"

# REUSE-IgnoreStart
class TemplateRendererTest < DevtoolsTest
  TEMPLATES = File.expand_path("../../lib/ratatui_ruby/devtools/templates", __dir__)

  def test_starts_the_gem_at_zero_zero_zero
    in_scaffold do |gem|
      assert_includes gem.read("lib/probe_gem/version.rb"), %(VERSION = "0.0.0")
    end
  end

  def test_credits_the_author_in_every_notice
    in_scaffold do |gem|
      %w[CHANGELOG.md .gitignore REUSE.toml README.md].each do |path|
        assert_includes gem.read(path), "#{this_year} Probe Person <probe@example.com>", path
      end
      assert_empty gem.files_mentioning("Kerrick")
    end
  end

  def test_starts_a_changelog_whose_first_bump_links_its_release
    in_scaffold do |gem|
      assert_includes gem.read("CHANGELOG.md"), "[Unreleased]: https://github.com/setdef/ProbeGem/tree/HEAD\n"

      Changelog.new(path: gem.path("CHANGELOG.md")).release(SemVer.parse("0.1.0"))

      assert_includes gem.read("CHANGELOG.md"), "[0.1.0]: https://github.com/setdef/ProbeGem/releases/tag/v0.1.0\n"
    end
  end

  def test_tests_each_supported_minor_version_of_ruby
    in_scaffold(rust: true) do |gem|
      assert_includes gem.read(".github/workflows/ci.yml"), %(ruby: ["3.3", "3.4", "4.0"])
      assert_includes gem.read(".github/workflows/build-gems.yml"), %(ruby: ["3.3", "3.4", "4.0"])
    end
  end

  def test_tests_with_minitest_six
    in_scaffold do |gem|
      assert_includes gem.read("Gemfile"), %(gem "minitest", "~> 6.0")
      assert_includes gem.read("probe_gem.gemspec"), %(spec.add_development_dependency "minitest-mock")
    end
  end

  def test_installs_the_bundle_inside_the_gem
    in_scaffold do |gem|
      assert_includes gem.read("bin/setup"), "bundle config set --local path vendor/bundle"
      assert_includes gem.read(".gitignore"), "/vendor/bundle/\n"
    end
  end

  def test_says_initial_development_rather_than_pre_release
    in_scaffold do |gem|
      assert_includes gem.read("README.md"), "is in **initial development**, before 1.0."
      assert_empty gem.files_mentioning(/pre-release/i)
    end
  end

  def test_writes_only_the_task_files_a_gem_reads
    in_scaffold do |gem|
      assert gem.exist?("tasks/example_viewer.html.erb")
      refute gem.exist?("tasks/resources")
      refute gem.exist?(".builds")
    end
  end

  def test_an_update_leaves_the_changelog_alone
    in_scaffold do |gem|
      File.write(gem.path("CHANGELOG.md"), "# Our own changelog\n")

      render(gem.root, update_mode: true)

      assert_equal "# Our own changelog\n", gem.read("CHANGELOG.md")
    end
  end

  # A gem the scaffold rendered, read by its paths.
  ScaffoldedGem = Data.define(:root) do
    def path(relative)
      File.join(root, relative)
    end

    def read(relative)
      File.read(path(relative))
    end

    def exist?(relative)
      File.exist?(path(relative))
    end

    def files_mentioning(pattern)
      Dir.glob("**/*", File::FNM_DOTMATCH, base: root)
        .select { |relative| File.file?(path(relative)) && read(relative).match?(pattern) }
    end
  end

  # Renders the scaffold of a gem named probe_gem for Probe Person into a
  # directory of its own.
  private def in_scaffold(rust: false)
    Dir.mktmpdir do |parent|
      root = File.join(parent, "probe_gem")
      render(root, rust:)
      yield ScaffoldedGem.new(root:)
    end
  end

  private def render(root, rust: false, update_mode: false)
    config = ScaffoldConfig.new
    config.gem_name = "probe_gem"
    config.author = "Probe Person"
    config.email = "probe@example.com"
    config.has_rust = rust
    config.output_dir = root
    # An empty input declines every overwrite an update asks about, as
    # pressing Return does, so no test waits on the terminal.
    capture_io { TemplateRenderer.new(config, TEMPLATES, root, update_mode:, input: StringIO.new).render_all }
  end
end
# REUSE-IgnoreEnd
