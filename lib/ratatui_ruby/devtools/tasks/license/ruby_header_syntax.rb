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

  def extensions
    %w[rb]
  end

  def directories
    %w[lib ext test examples tasks bin]
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
end
