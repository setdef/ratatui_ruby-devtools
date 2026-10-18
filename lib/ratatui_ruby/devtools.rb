# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

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
      attr_writer :gem_name, :gemspec_file, :version_file

      # Loads gem development Rake tasks (test, lint, bump, license, etc.)
      #
      # Use this in gem/library Rakefiles. These tasks help with version
      # management, testing, linting, and releasing gems.
      #
      # === Example
      #
      #   require "ratatui_ruby/devtools"
      #   RatatuiRuby::Devtools.install_gem_tasks!
      #
      def install_gem_tasks!
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
        tasks_dir = File.expand_path("devtools/#{subdir}", __dir__)
        Dir.glob("#{tasks_dir}/*.rake").each do |task_file|
          Rake.application.add_import(task_file)
        end
        Rake.application.load_imports
      end

      # Returns the gem name, auto-discovered from gemspec if not set.
      #
      # Tasks need to know which gem they're operating on. Auto-discovery from
      # gemspec files means zero configuration for standard layouts. Override
      # via <tt>gem_name=</tt> if needed.
      def gem_name
        @gem_name ||= discover_gem_name
      end

      # Returns the path to the gemspec file.
      #
      # Tasks parse the gemspec for metadata. Auto-discovery finds the single
      # <tt>.gemspec</tt> file in the project root. Override via
      # <tt>gemspec_file=</tt> for non-standard layouts.
      def gemspec_file
        @gemspec_file ||= discover_gemspec
      end

      # Returns the path to the version.rb file.
      #
      # Version bumping needs the version file location. Auto-discovery finds
      # it in the standard <tt>lib/*/</tt> path. Override via
      # <tt>version_file=</tt> for non-standard layouts.
      def version_file
        @version_file ||= discover_version_file
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

      private def discover_gemspec
        gemspecs = Dir.glob("*.gemspec")
        raise Error, "No *.gemspec found in #{Dir.pwd}" if gemspecs.empty?
        raise Error, "Multiple gemspecs found: #{gemspecs.join(', ')}" if gemspecs.size > 1

        gemspecs.first
      end

      private def discover_gem_name
        File.basename(gemspec_file, ".gemspec")
      end

      private def discover_version_file
        # Convention: lib/gem_name/version.rb (with underscores for namespacing)
        # e.g., ratatui_ruby-kit -> lib/ratatui_ruby/kit/version.rb
        parts = gem_name.split("-")
        if parts.size > 1
          # ratatui_ruby-kit -> ratatui_ruby/kit
          path = "lib/#{parts.first}/#{parts[1..].join('/')}/version.rb"
        else
          # ratatui_ruby -> ratatui_ruby
          path = "lib/#{gem_name}/version.rb"
        end

        return path if File.exist?(path)

        # Fallback: search for any version.rb in lib/
        found = Dir.glob("lib/**/version.rb").first
        found || path
      end
    end
  end
end
