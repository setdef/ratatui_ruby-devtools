# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# A code example inside a file, wrapped from its first to its last line
# counting from 0, behind the given comment prefix. Its year comes from the
# code lines alone, which can sit inside markers the wrapper goes around. One
# already wrapped carries its SnippetOpening.
class Snippet < Data.define(:first, :last, :prefix, :code, :opening) # :nodoc:
  # REUSE 3.3 requires copyright notices inside a snippet to use the snippet
  # tag. Earlier wrappers used the file tag.
  # REUSE-IgnoreStart
  COPYRIGHT_TAG = "SPDX-SnippetCopyrightText"
  FILE_COPYRIGHT_TAG = "SPDX-FileCopyrightText"
  # REUSE-IgnoreEnd

  def self.around(first, last, prefix: "", code: [first, last], opening: nil)
    new(first:, last:, prefix:, code:, opening:)
  end

  # A line of a wrapper's tags, using the snippet copyright tag.
  def self.tag(line)
    line.sub(FILE_COPYRIGHT_TAG, COPYRIGHT_TAG)
  end

  # The code lines as git blame counts them, from 1.
  def blame_range
    code.map { |line| line + 1 }
  end

  def lines_in(file_lines)
    file_lines[first..last]
  end
end
