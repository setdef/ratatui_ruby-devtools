# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/bump/ruby_gem"
require "ratatui_ruby/devtools/tasks/lint_tasks"

class LintTasksTest < DevtoolsTest
  def test_lints_rust_only_in_a_gem_with_an_extension
    in_gem do
      LintTasks.new(RubyGem.found)

      assert_equal %w[rubocop rubycritic lockfile_ruby], Rake::Task["lint:code"].prerequisites
    end
    in_gem("ext/fixture/Cargo.toml") do
      LintTasks.new(RubyGem.found)

      assert_equal %w[rubocop rubycritic lockfile_ruby cargo:fmt cargo:clippy cargo:test], Rake::Task["lint:code"].prerequisites
    end
  end

  def test_checks_the_lockfile_against_the_oldest_ruby_its_gem_supports
    in_gem(required_ruby_version: ">= 2.0") do
      LintTasks.new(RubyGem.found)

      error = assert_raises(SystemExit) do
        assert_output(nil, /need a newer Ruby than 2.0, the oldest the gemspec supports/) do
          Rake::Task["lint:lockfile_ruby"].invoke
        end
      end
      refute error.success?
    end
  end

  # Runs the block in a gem holding +files+, with a Rake application of its
  # own.
  private def in_gem(*files, required_ruby_version: ">= 3.3")
    application = Rake.application
    Dir.mktmpdir do |root|
      Dir.chdir(root) do
        File.write("fixture.gemspec", %(Gem::Specification.new { |spec| spec.name = "fixture"; spec.required_ruby_version = "#{required_ruby_version}" }))
        files.each do |path|
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, "")
        end
        Rake.application = Rake::Application.new
        yield
      end
    end
  ensure
    Rake.application = application
  end
end
