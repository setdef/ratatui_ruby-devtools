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
  # From 1.0 on, each minor version gets a release branch, so its users can
  # take patch releases without the next minor's changes. The version a bump
  # releases decides which branch it belongs on, whichever segment named it:
  # a patch bump that finishes 1.0.0-beta.1 opens the 1.0 series.
  def self.for(gem, segment)
    target = gem.version.next(segment)
    workflow = if !target.stable?
      UnbranchedRelease
    elsif target.patch.zero?
      ReleaseFromTrunk
    else
      PatchRelease
    end
    workflow.new(gem:, segment:, target:)
  end

  def initialize(gem:, segment:, target:, repository: Repository.new)
    @gem = gem
    @segment = segment
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

    raise ArgumentError, "Cannot bump:#{@segment} from #{@repository.current_branch}. Switch to trunk first."
  end

  # Template methods for subclasses
  private def prepare = nil
  private def finalize = nil
end
