# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# A Snippet that already has its wrapper, opened by its SnippetOpening.
class WrappedSnippet < Data.define(:snippet, :opening) # :nodoc:
  def first
    snippet.first
  end

  def covers?(other)
    other.first.between?(snippet.first, snippet.last)
  end

  def blame_range
    snippet.blame_range
  end

  def bare?
    false
  end

  def revise(revision)
    renewal = opening.renewal(revision.contributions(self), revision.license)
    revision.reopen(snippet, renewal) if renewal.changed?
  end
end
