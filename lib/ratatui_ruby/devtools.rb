# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "devtools/task_scope"
require_relative "devtools/tasks/autodoc_tasks"
require_relative "devtools/tasks/bump/ruby_gem"
require_relative "devtools/tasks/bump_tasks"
require_relative "devtools/tasks/cargo_tasks"
require_relative "devtools/tasks/doc_tasks"
require_relative "devtools/tasks/license/licensing"
require_relative "devtools/tasks/license_tasks"
require_relative "devtools/tasks/lint_tasks"
require_relative "devtools/tasks/release_tasks"
require_relative "devtools/tasks/reuse_tasks"
require_relative "devtools/tasks/test_tasks"
require_relative "devtools/tasks/website_tasks"
require_relative "devtools/version"

# Root namespace for RatatuiRuby ecosystem gems.
#
# This gem provides development tooling shared across the ecosystem. Consumer
# gems require this and call <tt>Devtools.install!</tt> to load Rake tasks.
module RatatuiRuby
  # Development tooling for the RatatuiRuby ecosystem.
  #
  # This gem provides shared Rake tasks, linter configurations, and build
  # tooling used across all RatatuiRuby ecosystem gems.
  #
  # == Usage
  #
  # In your Rakefile:
  #
  #   require "ratatui_ruby/devtools"
  #   RatatuiRuby::Devtools.install!
  #
  #   # Optional: import project-specific tasks
  #   Dir.glob("tasks/*.rake").each { |r| import r }
  #
  #   task default: %w[lint:fix test lint]
  #
  module Devtools
    # Base error class for devtools failures.
    #
    # Rake tasks may encounter errors during configuration discovery or task
    # execution. This class provides a common base for all devtools exceptions.
    class Error < StandardError; end

    class << self
      # Loads gem development Rake tasks (test, lint, bump, license, etc.)
      #
      # Use this in gem/library Rakefiles. These tasks help with version
      # management, testing, linting, and releasing gems.
      #
      # The tasks find your gemspec, your gem's name, and its version file
      # from your gem's files. Pass any of them when your gem keeps them
      # elsewhere, and pass how to license the code apps don't link.
      #
      # [gemspec_file] Your gemspec, when your gem has more than one.
      # [gem_name] Your gem's name, when it differs from your gemspec's.
      # [version_file] The file that defines your gem's +VERSION+.
      # [non_runtime_license] The license for code apps don't link: tests,
      #   tasks, scripts, type signatures, and examples.
      #   <tt>"AGPL-3.0-or-later"</tt> unless you pass another.
      # [snippet_paths] Path prefixes for code licensed MIT-0, like the
      #   snippets in your docs. None unless you pass them.
      #
      # === Examples
      #
      #   require "ratatui_ruby/devtools"
      #   RatatuiRuby::Devtools.install_gem_tasks!
      #
      #   RatatuiRuby::Devtools.install_gem_tasks!(
      #     snippet_paths: %w[examples/widget_ examples/verify_],
      #     non_runtime_license: "LicenseRef-Commercial"
      #   )
      #
      def install_gem_tasks!(
        gemspec_file: nil,
        gem_name: nil,
        version_file: nil,
        non_runtime_license: "AGPL-3.0-or-later",
        snippet_paths: []
      )
        AutodocTasks.new
        CargoTasks.new
        DocTasks.new
        TestTasks.new
        gem = RubyGem.found(gemspec_file:, name: gem_name, version_file:)
        BumpTasks.new(gem)
        ReleaseTasks.new(gem)
        WebsiteTasks.new(gem)
        LintTasks.new(gem)
        licensing = Licensing.of(gem.spec, snippets: snippet_paths, non_runtime: non_runtime_license)
        LicenseTasks.new(licensing)
        ReuseTasks.new(licensing)
      end

      # Loads website hosting Rake tasks (build, serve, deploy).
      #
      # Use this in website repository Rakefiles. These tasks help sync docs
      # from a source gem, update HTML metadata, and deploy.
      #
      # [source_gem_dir] Path to the source gem's directory, such as
      #   <tt>"~/Developer/ratatui_ruby"</tt>.
      #
      # === Example
      #
      #   require "ratatui_ruby/devtools"
      #   RatatuiRuby::Devtools.install_website_tasks!(
      #     source_gem_dir: "~/Developer/ratatui_ruby"
      #   )
      #
      def install_website_tasks!(source_gem_dir:)
        @source_gem_dir = File.expand_path(source_gem_dir)
        load_tasks_from("site_tasks")
      end

      # Returns the source gem directory for website tasks.
      attr_reader :source_gem_dir

      # Backwards-compatible alias for install_gem_tasks!
      alias install! install_gem_tasks!

      private def load_tasks_from(subdir)
        TaskScope.new.load(File.expand_path("devtools/#{subdir}", __dir__))
      end

      # Returns the path to the templates directory.
      #
      # Scaffolding commands copy files from templates. This method provides
      # the absolute path regardless of caller location.
      def templates_path
        File.expand_path("devtools/templates", __dir__)
      end

      # Returns the path to the tasks directory.
      #
      # Debug and introspection tools may need to list available tasks. This
      # method provides the absolute path regardless of caller location.
      def tasks_path
        File.expand_path("devtools/tasks", __dir__)
      end
    end
  end
end
