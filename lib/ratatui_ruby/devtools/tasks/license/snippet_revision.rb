# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "blame"
require_relative "copyright"

# One file's snippets brought up to date: each bare snippet asks to be
# wrapped, and each wrapped one whose notices have moved on asks to be
# reopened.
class SnippetRevision # :nodoc:
  attr_reader :snippets

  def initialize(path:, text:, syntax:, author:)
    @syntax = syntax
    @author = author
    @lines = syntax.cleaned(text.lines)
    @snippets = syntax.snippets_in(@lines)
    # Blame reads the cleaned lines the snippets were found in, not the file
    # on disk.
    @blame = Blame.new(path:, contents: @lines.join)
  end

  # Revises from the last snippet back, so the earlier ones stay on the lines
  # blame found them on.
  def run
    @snippets.reverse_each { |snippet| snippet.revise(self) }
    self
  end

  def text
    @lines.join
  end

  def contributions(snippet)
    @blame.contributions([snippet.blame_range], uncommitted_by: @author)
  end

  def license
    @syntax.license
  end

  def wrap(snippet)
    copyrights = contributions(snippet).map { |contribution| Copyright.of(contribution) }.sort_by(&:holder)
    @lines.insert(snippet.last + 1, *@syntax.closing(snippet))
    @lines.insert(snippet.first, *@syntax.opening(snippet, copyrights))
  end

  def reopen(snippet, opening)
    @lines[opening.span] = @syntax.opening(snippet, opening.copyrights)
  end
end
