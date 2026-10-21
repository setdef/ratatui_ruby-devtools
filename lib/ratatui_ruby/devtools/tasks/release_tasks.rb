# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rake/tasklib"

require_relative "bump/repository"
require_relative "release/platform_gem"

# The tasks that release a gem and its native gems.
class ReleaseTasks < Rake::TaskLib # :nodoc:
  def initialize(gem, repository: Repository.new)
    super()
    @gem = gem
    @repository = repository
    define
  end

  private def define
    namespace :release do
      desc "Package the precompiled binaries in lib/ into a platform gem"
      task :platform_gem do
        PlatformGem.new(@gem).build
      end

      desc "Update stable branch to match release and set as default"
      task :update_stable do
        version = @gem.release_version

        # A release that failed leaves the version file ahead of the tags, and
        # stable would then point at the wrong version.
        latest_tag = @repository.latest_tag
        if latest_tag != version.to_tag
          abort "Fatal: Version mismatch! '#{@gem.version_file}' says #{version.to_tag}, " \
            "but the latest git tag is #{latest_tag}."
        end

        stable = @gem.stable_version(@repository)
        if stable && version.to_gem_version <= stable
          puts "Skipping stable update: #{version} is not newer than current stable #{stable}"
          next
        end

        puts "Updating stable branch to point to #{version.to_tag}..."
        @repository.move_stable(@repository.released_commit(version.to_tag))
      end
    end

    if Rake::Task.task_defined?("release")
      release = Rake::Task["release"]

      # Bundler tags and publishes in the release task's prerequisites, so a
      # version its tag can't name has to stop the release before they run.
      task "release:check_version" do
        @gem.release_version
      end
      release.prerequisites.unshift("release:check_version")

      release.enhance do
        version = @gem.release_version

        # Bundler tags the release v plus the version as RubyGems writes it, so
        # a prerelease gets a tag like v1.0.0.pre.beta.1 that isn't SemVer.
        normalized_tag = "v#{version.to_gem_version}"
        if normalized_tag != version.to_tag
          puts "Replacing normalized tag #{normalized_tag} with semver tag #{version.to_tag}..."
          @repository.delete_tag(normalized_tag)
          @repository.tag_head(version.to_tag)
        end

        @gem.crate.release_native_gems(version: version.to_s, sha: @repository.released_commit(version.to_tag))

        Rake::Task["release:update_stable"].invoke
      end
    end
  end
end
