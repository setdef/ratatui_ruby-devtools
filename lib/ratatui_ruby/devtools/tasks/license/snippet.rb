# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# A code example inside a file, wrapped from its first to its last line
# counting from 0, behind the given comment prefix. Its year comes from the
# code lines alone, which can sit inside markers the wrapper goes around.
class Snippet < Data.define(:first, :last, :prefix, :code) # :nodoc:
  def self.around(first, last, prefix: "", code: [first, last])
    new(first:, last:, prefix:, code:)
  end

  # The code lines as git blame counts them, from 1.
  def blame_range
    code.map { |line| line + 1 }
  end

  def lines_in(file_lines)
    file_lines[first..last]
  end
end
