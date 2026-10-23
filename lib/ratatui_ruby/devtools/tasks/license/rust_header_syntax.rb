# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "copyright"
require_relative "directory_licensing"
require_relative "existing_header"
require_relative "missing_header"
require_relative "spdx_header"

class RustHeaderSyntax # :nodoc:
  include DirectoryLicensing

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
    last_tag = nil
    lines.each_with_index do |line, index|
      case line
      when COPYRIGHT
        copyrights << Copyright.new(year: $1.to_i, holder: $2.strip)
        last_tag = index
      when LICENSE
        license = $1.strip
        last_tag = index
      else
        next if line.start_with?("//")
        break if license || !line.strip.empty?
      end
    end
    return MissingHeader.new unless last_tag

    ExistingHeader.new(header: SpdxHeader.new(copyrights:, license:), end_line: last_tag)
  end

  def added(header, lines)
    "#{header.commented('//')}\n#{lines.join}"
  end

  def replaced(header, lines, end_line)
    opening = preamble(lines, end_line)
    "#{opening.join}#{"\n" if opening.any?}#{header.commented('//')}\n#{after_header(lines, end_line).join}"
  end

  # The file's own comments among the header's, which stay above the new
  # header.
  private def preamble(lines, end_line)
    lines.take(end_line + 1).reject do |line|
      line.match?(COPYRIGHT) || line.match?(LICENSE) || line.match?(%r{^//\s*$}) || line.strip.empty?
    end
  end
end
