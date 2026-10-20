# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rdoc"
require_relative "rdoc_examples"
require_relative "snippet"

# A run of comment lines, read the way RDoc reads it. Indentation alone
# doesn't make an example: a list item's continuation and a call-seq are
# indented too, and blank lines after an example aren't part of it.
class RdocComment < Data.define(:first, :prefix, :lines) # :nodoc:
  def self.all_in(file_lines)
    file_lines.each_with_index
      .select { |line, _| prefix_of(line) }
      .chunk_while { |(line, index), (other, other_index)| other_index == index + 1 && prefix_of(other) == prefix_of(line) }
      .map { |run| new(first: run.first.last, prefix: prefix_of(run.first.first), lines: run.map(&:first)) }
  end

  def self.prefix_of(line)
    line[/\A(\s*)#/, 1]
  end

  # RDoc's markup carries no line numbers, and its own steps drop lines on
  # the way, so each example is found again by all of its lines.
  def examples
    cursor = 0
    RDoc::Markup.parse(markup).accept(RdocExamples.new).filter_map do |verbatim|
      code = verbatim.text.lines.map(&:strip)
      start = cursor.upto(lines.length - code.length).find { |index| code_at?(index, code) }
      next unless start

      cursor = start + code.length
      Snippet.around(first + start, first + cursor - 1, prefix:)
    end
  end

  private def markup
    comment = RDoc::Comment.new(lines.join, nil, :ruby)
    comment.remove_private
    comment.normalize
    comment.extract_call_seq
    comment.text
  end

  private def code_at?(index, code)
    lines[index, code.length].map { |line| line.sub(/\A\s*#+/, "").strip } == code
  end
end
