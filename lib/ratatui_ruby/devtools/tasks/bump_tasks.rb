# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rake/tasklib"
require "rubygems"

require_relative "bump/sem_ver"
require_relative "bump/release_from_trunk"
require_relative "bump/patch_release"
require_relative "bump/unbranched_release"

# The tasks that bump a gem's version.
class BumpTasks < Rake::TaskLib # :nodoc:
  def initialize(gem)
    super()
    @gem = gem
    define
  end

  private def define
    namespace :bump do
      desc "Bump major version"
      task :major do
        BumpWorkflow.for(@gem, :major).call(:major)
      end

      desc "Bump minor version"
      task :minor do
        BumpWorkflow.for(@gem, :minor).call(:minor)
      end

      desc "Bump patch version"
      task :patch do
        BumpWorkflow.for(@gem, :patch).call(:patch)
      end

      desc "Set exact version (e.g. rake bump:exact[0.1.0])"
      task :exact, [:version] do |_, args|
        target = SemVer.parse(args[:version])
        changelog = Changelog.new
        changelog.release(target)
        @gem.update_version(target)
      end
    end
  end
end
