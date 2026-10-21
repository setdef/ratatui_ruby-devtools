# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "erb"
require "rake/tasklib"
require "fileutils"
require "tmpdir"
require_relative "rdoc_config"

# The task that builds a gem's documentation website.
class WebsiteTasks < Rake::TaskLib # :nodoc:
  def initialize(gem)
    super()
    @gem = gem
    define
  end

  private def define
    namespace :website do
      desc "Build documentation for trunk (current dir) and all git tags"
      task :build do
        require_relative "website/website"

        spec = @gem.spec
        globs = RDocConfig::RDOC_FILES + ["*.gemspec", "doc/images/**/*", "examples/**/*"]

        # Allow projects to customize via website_config.rb in their tasks/ directory
        config = if File.exist?("tasks/website_config.rb")
          load File.expand_path("tasks/website_config.rb", Dir.pwd)
          WebsiteConfig::CONFIG
        else
          {}
        end

        Website.new(
          at: config[:output_dir] || "www",
          project_name: spec.name,
          globs:,
          assets: config[:assets] || ["doc/images"],
          branding: config[:branding] || {}
        ).build
      end
    end
  end
end
