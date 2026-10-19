# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "directory_licensing"
require_relative "ruby_comment_header"

# RBS has no magic comments, so its header opens the file.
class RbsHeaderSyntax # :nodoc:
  include DirectoryLicensing
  include RubyCommentHeader

  def extensions
    %w[rbs]
  end

  def directories
    %w[sig]
  end

  def added(header, lines)
    "#{block(header)}\n#{lines.drop_while { |line| line.strip.empty? }.join}"
  end

  def replaced(header, lines, end_line)
    "#{block(header)}\n#{after_header(lines, end_line).join}"
  end
end
