# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "copyright"
require_relative "spdx_header"

# The header sits between #-- and #++ so RDoc leaves it out of the docs.
class RubyHeaderSyntax # :nodoc:
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

  def header_in(lines)
    copyrights = []
    license = nil
    lines.each_with_index do |line, index|
      case line
      when COPYRIGHT then copyrights << Copyright.new(year: $1.to_i, holder: $2.strip)
      when LICENSE then license = $1.strip
      when /^#\+\+\s*$/ then return [SpdxHeader.new(copyrights:, license:), index] if copyrights.any? || license
      end
    end
    [SpdxHeader.new(copyrights:, license:), 0] if copyrights.any? || license
  end

  def added(header, lines)
    frozen = frozen_string_literal_in(lines)
    return "#{frozen}\n#{block(header)}\n#{lines.drop(1).join}" if frozen

    "#{FROZEN_STRING_LITERAL}\n#{block(header)}\n#{lines.join}"
  end

  def replaced(header, lines, body)
    frozen = frozen_string_literal_in(lines)
    preamble = if frozen
      "#{frozen}\n"
    elsif lines.first.strip.empty?
      FROZEN_STRING_LITERAL
    else
      "#{FROZEN_STRING_LITERAL}\n"
    end
    "#{preamble}#{block(header)}\n#{body.join}"
  end

  private def frozen_string_literal_in(lines)
    lines.first if lines.first&.include?("frozen_string_literal")
  end

  private def block(header)
    "#--\n#{header.commented('#')}#++\n"
  end
end
