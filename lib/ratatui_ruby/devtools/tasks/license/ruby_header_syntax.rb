# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "directory_licensing"
require_relative "ruby_comment_header"

class RubyHeaderSyntax # :nodoc:
  include DirectoryLicensing
  include RubyCommentHeader

  FROZEN_STRING_LITERAL = "# frozen_string_literal: true\n"
  # Ruby finds an encoding wherever "coding" meets a colon or equals sign, as
  # in Emacs and Vim modelines.
  ENCODING_COMMENT = /\A#.*coding[:=]/
  MAGIC_COMMENT = /\A#.*(coding[:=]|\b(frozen_string_literal|warn_indent|shareable_constant_value)\s*:)/

  def extensions
    %w[rb]
  end

  def directories
    %w[lib ext test examples tasks bin]
  end

  def added(header, lines)
    opening = lines.take_while { |line| line.start_with?("#!") || line.match?(MAGIC_COMMENT) }
    body = lines.drop(opening.length).drop_while { |line| line.strip.empty? }
    "#{frozen(opening).join}\n#{block(header)}\n#{body.join}"
  end

  def replaced(header, lines, end_line)
    "#{frozen(preamble(lines, end_line)).join}\n#{block(header)}\n#{after_header(lines, end_line).join}"
  end

  # Ruby reads a shebang only on the first line, and an encoding comment only
  # on the first line or right after a shebang.
  private def frozen(opening)
    return opening if opening.any? { |line| line.include?("frozen_string_literal") }

    first_lines = opening.take_while { |line| line.start_with?("#!") || line.match?(ENCODING_COMMENT) }
    opening.dup.insert(first_lines.length, FROZEN_STRING_LITERAL)
  end
end
