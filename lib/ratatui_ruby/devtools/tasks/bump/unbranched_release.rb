# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "bump_workflow"

# Before 1.0 there is no older series to patch, so every release happens on
# trunk and no release branch is cut.
class UnbranchedRelease < BumpWorkflow # :nodoc:
  private def assert_can_bump!(segment)
    @repository.assert_pristine!
    return if @repository.on_trunk?

    raise ArgumentError, "Cannot bump:#{segment} from #{@repository.current_branch}. Switch to trunk first."
  end

  private def prepare(segment)
    puts "Bumping #{segment}: #{@gem.version} -> #{target}"
  end

  private def finalize
    puts "\nCommitted. Push and run: bundle exec rake release"
  end
end
