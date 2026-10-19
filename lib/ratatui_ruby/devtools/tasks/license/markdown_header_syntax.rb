# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "blame"
require_relative "copyright"
require_relative "markdown_document"
require_relative "spdx_header"

class MarkdownHeaderSyntax # :nodoc:
  LICENSE = "CC-BY-SA-4.0"
  # REUSE-IgnoreStart
  COPYRIGHT = /SPDX-FileCopyrightText:\s*(\d{4})\s+(.+)$/
  LICENSE_LINE = /SPDX-License-Identifier:\s*(.+)$/
  # REUSE-IgnoreEnd

  def extensions
    %w[md]
  end

  def covers?(path)
    path.end_with?(".md")
  end

  def tracked_patterns
    ["*.md"]
  end

  def license_for(_path)
    LICENSE
  end

  # Code blocks hold examples rather than prose, so only prose lines count
  # toward who wrote the document and when.
  def contributions(path, lines, author)
    Blame.new(path).contributions(prose_ranges(lines), uncommitted_by: author)
  end

  def header_in(lines)
    closing = comment_end(lines)
    return unless closing

    comment = lines[..closing]
    copyrights = comment.grep(COPYRIGHT) { Copyright.new(year: $1.to_i, holder: $2.strip) }
    license = comment.grep(LICENSE_LINE) { $1.strip }.last
    [SpdxHeader.new(copyrights:, license:), closing] if copyrights.any? || license
  end

  def added(header, lines)
    "#{block(header)}#{lines.join}"
  end

  def replaced(header, lines, end_line)
    "#{block(header)}#{lines.drop(end_line + 1).join}"
  end

  private def block(header)
    "<!--\n#{header.commented(' ')}-->\n"
  end

  # Line ranges counting from 1, between the header and each code block.
  private def prose_ranges(lines)
    start = header_length(lines)
    ranges = []
    code_blocks(lines).each do |first, last|
      ranges << [start + 1, first] if start < first
      start = last + 1
    end
    ranges << [start + 1, lines.length] if start < lines.length
    ranges
  end

  private def header_length(lines)
    closing = comment_end(lines)
    closing ? closing + 1 : 0
  end

  # The index of the line closing a comment that opens the file.
  private def comment_end(lines)
    lines.index { |line| line.include?("-->") } if lines.first&.include?("<!--")
  end

  private def code_blocks(lines)
    document = MarkdownDocument.new(lines)
    blocks = []
    index = 0
    while index < lines.length
      closing = document.fence_end(index)
      if closing
        blocks << [index, closing]
        index = closing
      end
      index += 1
    end
    blocks
  end
end
