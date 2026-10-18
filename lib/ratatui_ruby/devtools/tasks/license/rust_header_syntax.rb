# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "copyright"
require_relative "spdx_header"

class RustHeaderSyntax # :nodoc:
  # REUSE-IgnoreStart
  COPYRIGHT = %r{^//\s*SPDX-FileCopyrightText:\s*(\d{4})\s+(.+)$}
  LICENSE = %r{^//\s*SPDX-License-Identifier:\s*(.+)$}
  # REUSE-IgnoreEnd

  def extensions
    %w[rs]
  end

  def directories
    %w[ext]
  end

  def header_in(lines)
    copyrights = []
    license = nil
    end_line = nil
    lines.each_with_index do |line, index|
      case line
      when COPYRIGHT then copyrights << Copyright.new(year: $1.to_i, holder: $2.strip)
      when LICENSE
        license = $1.strip
        end_line = index
      else
        next if line.start_with?("//")
        break if end_line || !line.strip.empty?
      end
    end
    [SpdxHeader.new(copyrights:, license:), end_line || 0] if copyrights.any? || license
  end

  def added(header, lines)
    "#{header.commented('//')}\n#{lines.join}"
  end

  def replaced(header, _lines, body)
    "#{header.commented('//')}\n#{body.join}"
  end
end
