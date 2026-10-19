# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "spdx_header"

# One file's license header brought up to date: the header the file has asks
# to be replaced, or the one it lacks asks to be added.
class HeaderRevision # :nodoc:
  attr_reader :text, :report

  def initialize(path:, lines:, syntax:, author:)
    @path = path
    @lines = lines
    @syntax = syntax
    @author = author
  end

  def contributions
    @contributions ||= @syntax.contributions(@path, @lines, @author)
  end

  def license
    @syntax.license_for(@path)
  end

  def replace(header, end_line)
    @text = @syntax.replaced(header, @lines, end_line)
    @report = "Updated: #{@path}"
  end

  def add
    @text = @syntax.added(SpdxHeader.of(@author, contributions, license), @lines)
    @report = "Added header: #{@path}"
  end
end
