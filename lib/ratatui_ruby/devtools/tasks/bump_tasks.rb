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
      desc "Bump major version, or to a prerelease with a label (e.g. rake bump:major[beta])"
      task :major, [:label] do |_, args|
        BumpWorkflow.for(@gem, :major, args[:label]).call
      end

      desc "Bump minor version, or to a prerelease with a label (e.g. rake bump:minor[rc])"
      task :minor, [:label] do |_, args|
        BumpWorkflow.for(@gem, :minor, args[:label]).call
      end

      desc "Bump patch version, or to a prerelease with a label (e.g. rake bump:patch[rc])"
      task :patch, [:label] do |_, args|
        BumpWorkflow.for(@gem, :patch, args[:label]).call
      end

      desc "Set exact version (e.g. rake bump:exact[0.1.0])"
      task :exact, [:version] do |_, args|
        BumpWorkflow.to(@gem, SemVer.parse(args[:version]), :exact).call
      end
    end
  end
end
