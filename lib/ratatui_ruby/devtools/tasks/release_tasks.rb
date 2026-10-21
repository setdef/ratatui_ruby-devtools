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
        # Read version to determine tag
        version_file = @gem.version_file
        version_content = File.read(version_file)
        version = version_content.match(/VERSION = "(.+?)"/)[1]
        tag_name = "v#{version}"

        # Verify that the version file matches the actual git tag
        # This prevents updating stable to the wrong version if the release failed
        latest_tag = @repository.latest_tag
        if latest_tag != tag_name
          abort "Fatal: Version mismatch! '#{version_file}' says #{tag_name}, but the latest git tag is #{latest_tag}."
        end

        # Get current stable version (if stable branch exists)
        stable_version_str = @repository.stable_file(version_file)&.match(/VERSION = "(.+?)"/)&.[](1)
        if stable_version_str
          stable_version = Gem::Version.new(stable_version_str)
          new_version = Gem::Version.new(version)

          if new_version <= stable_version
            puts "Skipping stable update: #{version} is not newer than current stable #{stable_version_str}"
            next
          end
        end

        puts "Updating stable branch to point to #{tag_name}..."
        @repository.move_stable(@repository.released_commit(tag_name))
      end
    end

    if Rake::Task.task_defined?("release")
      Rake::Task["release"].enhance do
        # Replace Bundler's normalized tag with semver-style for prerelease versions.
        # Bundler creates tags using normalized Gem::Version (e.g., v1.0.0.pre.beta.1).
        # Semver uses hyphens (e.g., v1.0.0-beta.1). We want only the semver tag.
        version_file = @gem.version_file
        version_content = File.read(version_file)
        version = version_content.match(/VERSION = "(.+?)"/)[1]

        if version.include?("-")
          normalized_tag = "v#{Gem::Version.new(version)}"
          semver_tag = "v#{version}"

          if normalized_tag != semver_tag
            puts "Replacing normalized tag #{normalized_tag} with semver tag #{semver_tag}..."
            @repository.delete_tag(normalized_tag)
            @repository.tag_head(semver_tag)
          end
        end

        release_sha = @repository.released_commit("v#{version}")
        @gem.crate.release_native_gems(version:, sha: release_sha)

        Rake::Task["release:update_stable"].invoke
      end
    end
  end
end
