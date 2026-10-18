# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

class MarkdownDocument < Data.define(:lines) # :nodoc:
  FENCE = /^(````*)\w*$/

  def fence?(index)
    lines[index].match?(FENCE)
  end

  # The line that closes the fence opening at +index+, when one does.
  def fence_end(index)
    marker = lines[index][FENCE, 1]
    return unless marker

    closing = /^#{Regexp.escape(marker)}$/
    (index + 1).upto(lines.length - 1).find { |later| lines[later].match?(closing) }
  end
end
