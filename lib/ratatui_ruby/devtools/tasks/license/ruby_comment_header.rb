# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "copyright"
require_relative "existing_header"
require_relative "missing_header"
require_relative "spdx_header"

# Ruby and RBS share comments, so their headers sit between the same #-- and
# #++ that keep a Ruby header out of the docs.
module RubyCommentHeader # :nodoc:
  # REUSE-IgnoreStart
  COPYRIGHT = /^#\s*SPDX-FileCopyrightText:\s*(\d{4})\s+(.+)$/
  LICENSE = /^#\s*SPDX-License-Identifier:\s*(.+)$/
  # REUSE-IgnoreEnd

  # The header is in the comments the file opens with. Without its #++, it
  # ends at its last tag.
  def header_in(lines)
    copyrights = []
    license = nil
    last_tag = nil
    lines.each_with_index do |line, index|
      case line
      when COPYRIGHT
        copyrights << Copyright.new(year: $1.to_i, holder: $2.strip)
        last_tag = index
      when LICENSE
        license = $1.strip
        last_tag = index
      when /^#\+\+\s*$/
        return ExistingHeader.new(header: SpdxHeader.new(copyrights:, license:), end_line: index) if last_tag
      when /^\s*[^#\s]/
        break
      end
    end
    return MissingHeader.new unless last_tag

    ExistingHeader.new(header: SpdxHeader.new(copyrights:, license:), end_line: last_tag)
  end

  private def block(header)
    "#--\n#{header.commented('#')}#++\n"
  end

  # The file's own lines among the header's, such as a shebang or a linter
  # directive, which stay above the new header.
  private def preamble(lines, end_line)
    lines.take(end_line + 1).reject do |line|
      line.match?(COPYRIGHT) || line.match?(LICENSE) || line.match?(/^#(--|\+\+)?\s*$/) || line.strip.empty?
    end
  end
end
