# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# A code example inside a file, from its first to its last line counting
# from 0, written behind the given comment prefix.
class Snippet < Data.define(:first, :last, :prefix) # :nodoc:
  # The same lines as git blame counts them, from 1.
  def blame_range
    [first + 1, last + 1]
  end

  def lines_in(file_lines)
    file_lines[first..last]
  end
end
