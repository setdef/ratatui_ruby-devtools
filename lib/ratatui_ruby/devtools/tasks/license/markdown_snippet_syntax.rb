# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "markdown_document"
require_relative "snippet"
require_relative "snippet_opening"
require_relative "wrapped_snippet"

# Fenced code blocks, and the code synced into a README between SYNC markers,
# which the wrapper goes around so syncing doesn't erase it.
class MarkdownSnippetSyntax # :nodoc:
  LICENSE = "MIT-0"
  SYNC_START = /<!--\s*SYNC:START/
  SYNC_END = /<!--\s*SYNC:END/

  def extensions
    %w[md]
  end

  def tracked_patterns
    ["*.md"]
  end

  def license
    LICENSE
  end

  # Without the wrappers that don't license their code MIT-0, so the code they
  # held can be wrapped again, and with the copyright notices of the rest
  # under the snippet tag.
  def cleaned(lines)
    _, removals = scan(lines, first_pass: true)
    lines = lines.dup
    removals.sort_by { |first, _| -first }.each do |first, last|
      lines.delete_at(last)
      (opening_end(lines, first) - first + 1).times { lines.delete_at(first) }
    end
    lines.each_index.select { |index| lines[index].include?("SPDX-SnippetBegin") }.each do |first|
      first.upto(opening_end(lines, first)) { |index| lines[index] = Snippet.tag(lines[index]) }
    end
    lines
  end

  def snippets_in(lines)
    regions, = scan(lines, first_pass: false)
    regions
  end

  def opening(_snippet, copyrights)
    # REUSE-IgnoreStart
    [
      "<!-- SPDX-SnippetBegin -->\n",
      "<!--\n",
      *copyrights.map { |copyright| "  #{Snippet::COPYRIGHT_TAG}: #{copyright}\n" },
      "  SPDX-License-Identifier: #{LICENSE}\n",
      "-->\n",
    ]
    # REUSE-IgnoreEnd
  end

  def closing(_snippet)
    # REUSE-IgnoreStart
    ["<!-- SPDX-SnippetEnd -->\n"]
    # REUSE-IgnoreEnd
  end

  # The last line of the opening wrapper at +first+. A SnippetBegin comment
  # that closes on its own line is followed by the comment holding the SPDX
  # tags, which goes with it.
  private def opening_end(lines, first)
    start = tags_follow?(lines, first) ? first + 1 : first
    start.upto(lines.length - 1).find { |index| lines[index].include?("-->") } || (lines.length - 1)
  end

  private def tags_follow?(lines, first)
    lines[first].include?("-->") && lines[first + 1]&.include?("<!--")
  end

  # A wrapper from its SnippetBegin to its SnippetEnd, with the code between
  # its opening tags and its end.
  private def wrapped_region(lines, first, finish)
    opening = SnippetOpening.in(lines, first, opening_end(lines, first))
    return if opening.last + 1 > finish - 1

    WrappedSnippet.new(snippet: Snippet.around(first, finish, code: [opening.last + 1, finish - 1]), opening:)
  end

  # The first pass leaves MIT-0 wrappers alone and marks the rest for
  # removal. The second, after removal, reports the wrappers left with their
  # openings.
  private def scan(lines, first_pass:)
    document = MarkdownDocument.new(lines)
    regions = []
    removals = []
    index = 0
    while index < lines.length
      if lines[index].include?("SPDX-SnippetBegin")
        finish = index.upto(lines.length - 1).find { |later| lines[later].include?("SPDX-SnippetEnd") }
        if !first_pass
          wrapped = wrapped_region(lines, index, finish) if finish
          regions << wrapped if wrapped
          index = (finish || lines.length) + 1
          next
        elsif finish
          removals << [index, finish] unless licensed?(lines, index)
          index = finish + 1
          next
        end
      end

      region = sync_region(lines, document, index) || fence_region(document, index)
      if region
        regions << region
        index = region.last + 1
      else
        index += 1
      end
    end
    [regions, removals]
  end

  private def sync_region(lines, document, start)
    return unless lines[start].match?(SYNC_START)

    code_start = code_end = finish = nil
    (start + 1).upto(lines.length - 1) do |later|
      if document.fence?(later)
        if code_start
          code_end = later
        else
          code_start = later
        end
      elsif lines[later].match?(SYNC_END)
        finish = later
        break
      end
    end
    Snippet.around(start, finish, code: [code_start, code_end]) if code_start && code_end && finish
  end

  private def fence_region(document, start)
    finish = document.fence_end(start)
    Snippet.around(start, finish) if finish
  end

  # A wrapper that already credits someone under MIT-0 stays, whoever it
  # credits.
  private def licensed?(lines, begin_line)
    tags = lines[(begin_line + 1)..].take_while { |line| !line.include?("-->") }
    # REUSE-IgnoreStart
    tags.any? { |line| line.include?(Snippet::COPYRIGHT_TAG) || line.include?(Snippet::FILE_COPYRIGHT_TAG) } &&
      tags.any? { |line| line.include?(LICENSE) && line.include?("SPDX-License-Identifier") }
    # REUSE-IgnoreEnd
  end
end
