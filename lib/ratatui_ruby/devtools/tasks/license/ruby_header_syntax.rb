# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "copyright"
require_relative "directory_licensing"
require_relative "spdx_header"

# The header sits between #-- and #++ so RDoc leaves it out of the docs.
class RubyHeaderSyntax # :nodoc:
  include DirectoryLicensing

  FROZEN_STRING_LITERAL = "# frozen_string_literal: true\n"
  # REUSE-IgnoreStart
  COPYRIGHT = /^#\s*SPDX-FileCopyrightText:\s*(\d{4})\s+(.+)$/
  LICENSE = /^#\s*SPDX-License-Identifier:\s*(.+)$/
  # REUSE-IgnoreEnd

  def extensions
    %w[rb rbs]
  end

  def directories
    %w[lib ext test examples tasks bin sig]
  end

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
        return [SpdxHeader.new(copyrights:, license:), index] if last_tag
      when /^\s*[^#\s]/
        break
      end
    end
    [SpdxHeader.new(copyrights:, license:), last_tag] if last_tag
  end

  def added(header, lines)
    frozen = frozen_string_literal_in(lines)
    body = (frozen ? lines.drop(1) : lines).drop_while { |line| line.strip.empty? }
    "#{frozen || FROZEN_STRING_LITERAL}\n#{block(header)}\n#{body.join}"
  end

  def replaced(header, lines, end_line)
    frozen = frozen_string_literal_in(lines)
    "#{frozen || FROZEN_STRING_LITERAL}\n#{block(header)}\n#{after_header(lines, end_line).join}"
  end

  private def frozen_string_literal_in(lines)
    lines.first if lines.first&.include?("frozen_string_literal")
  end

  private def block(header)
    "#--\n#{header.commented('#')}#++\n"
  end
end
