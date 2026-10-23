# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "repository"
require_relative "changelog"

# Base class for version bump workflows.
# Subclasses implement the template methods: assert_can_bump!, prepare,
# release_on_branch, finalize.
class BumpWorkflow # :nodoc:
  def self.for(gem, segment, label = nil)
    to(gem, gem.version.next(segment, label), segment)
  end

  # From 1.0 on, each minor version gets a release branch, so its users can
  # take patch releases without the next minor's changes. The version a bump
  # releases decides which branch it belongs on, whichever task named it: a
  # patch bump that finishes 1.0.0-beta.1 opens the 1.0 series, and so does
  # an exact bump to 1.0.0.
  def self.to(gem, target, task)
    workflow = if !target.stable?
      UnbranchedRelease
    elsif target.patch.zero?
      ReleaseFromTrunk
    else
      PatchRelease
    end
    workflow.new(gem:, task:, target:)
  end

  def initialize(gem:, task:, target:, repository: Repository.new)
    @gem = gem
    @task = task
    @target = target
    @repository = repository
  end

  def call
    @repository.assert_pristine!
    assert_can_bump!

    prepare
    release_on_branch
    finalize
  end

  attr_reader :target

  private def release_on_branch
    changelog = Changelog.new
    @commit_message = changelog.commit_message(target)
    changelog.release(target)
    @gem.update_version(target)
    @repository.commit_all(@commit_message)
  end

  # Every release but a patch to an older series happens on trunk.
  private def assert_can_bump!
    return if @repository.on_trunk?

    raise ArgumentError, "Cannot bump:#{@task} from #{@repository.current_branch}. Switch to trunk first."
  end

  # Template methods for subclasses
  private def prepare = nil
  private def finalize = nil
end
