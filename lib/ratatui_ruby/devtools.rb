# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "devtools/task_scope"
require_relative "devtools/tasks/bump/ruby_gem"
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
      # Configuration accessors - auto-discovered if not set
      attr_writer :gem_name, :gemspec_file, :version_file, :non_runtime_license, :snippet_paths

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
      def install_gem_tasks!(gemspec_file: nil, gem_name: nil, version_file: nil, non_runtime_license: nil, snippet_paths: nil)
        { gemspec_file:, gem_name:, version_file:, non_runtime_license:, snippet_paths: }
          .compact.each { |setting, value| public_send(:"#{setting}=", value) }
        load_tasks_from("tasks")
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

      # Returns the gem name, auto-discovered from gemspec if not set.
      #
      # Tasks need to know which gem they're operating on. Auto-discovery from
      # gemspec files means zero configuration for standard layouts. Override
      # via <tt>gem_name=</tt> if needed.
      def gem_name
        gem_from_settings.name
      end

      # Returns the path to the gemspec file.
      #
      # Tasks parse the gemspec for metadata. Auto-discovery finds the single
      # <tt>.gemspec</tt> file in the project root. Override via
      # <tt>gemspec_file=</tt> for non-standard layouts.
      def gemspec_file
        gem_from_settings.gemspec_file
      end

      # Returns the path to the version.rb file.
      #
      # Version bumping needs the version file location. Auto-discovery finds
      # it in the standard <tt>lib/*/</tt> path. Override via
      # <tt>version_file=</tt> for non-standard layouts.
      def version_file
        gem_from_settings.version_file
      end

      # The license for code apps don't link.
      #
      # An app links the code it requires and the extensions it compiles.
      # The license tasks give that code the license in your gemspec. Tests,
      # tasks, scripts, type signatures, and examples never become part of
      # an app, so they get this license.
      #
      # Defaults to <tt>"AGPL-3.0-or-later"</tt>. Set
      # <tt>non_runtime_license=</tt> to license them differently, as a
      # commercial gem would.
      #
      # === Example
      #
      #   RatatuiRuby::Devtools.non_runtime_license = "LicenseRef-Commercial"
      #
      def non_runtime_license
        @non_runtime_license ||= "AGPL-3.0-or-later"
      end

      # Path prefixes for code licensed like the snippets in your docs.
      #
      # Some examples are snippets grown large. App developers copy them
      # whole into their own apps, so they need the same freedom as a
      # snippet. The license tasks give code under these prefixes MIT-0.
      #
      # Defaults to none.
      #
      # === Example
      #
      #   RatatuiRuby::Devtools.snippet_paths = %w[examples/widget_ examples/verify_]
      #
      def snippet_paths
        @snippet_paths ||= []
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

      private def gem_from_settings
        RubyGem.found(gemspec_file: @gemspec_file, name: @gem_name, version_file: @version_file)
      end
    end
  end
end
