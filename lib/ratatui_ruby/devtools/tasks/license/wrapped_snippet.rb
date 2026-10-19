# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# A Snippet that already has its wrapper, opened by its SnippetOpening.
class WrappedSnippet < Data.define(:snippet, :opening) # :nodoc:
  def blame_range
    snippet.blame_range
  end

  def bare?
    false
  end

  def revise(revision)
    renewed = opening.renewed(revision.contributions(self), revision.license)
    revision.reopen(snippet, renewed) unless renewed == opening
  end
end
