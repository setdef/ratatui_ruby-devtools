# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "spdx_header"

# One file's license header brought up to date: the header the file has asks
# to be replaced, or the one it lacks asks to be added.
class HeaderRevision # :nodoc:
  attr_reader :text

  def initialize(path:, lines:, syntax:, author:)
    @path = path
    @lines = lines
    @syntax = syntax
    @author = author
    @messages = []
  end

  def contributions
    @contributions ||= @syntax.contributions(@path, @lines, @author)
  end

  def license
    @syntax.license_for(@path)
  end

  def replace(renewal, end_line)
    @text = @syntax.replaced(renewal.value, @lines, end_line)
    @messages = [*renewal.notices.map { |notice| "  #{notice}" }, "Updated: #{@path}"]
  end

  def add
    @text = @syntax.added(SpdxHeader.of(@author, contributions, license), @lines)
    @messages = ["Added header: #{@path}"]
  end

  # What the revision did, for whoever ran it.
  def messages
    @messages.dup
  end
end
