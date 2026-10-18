# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "markdown_document"
require_relative "snippet"

# Fenced code blocks, and the code synced into a README between SYNC markers,
# which the wrapper goes around so syncing doesn't erase it.
class MarkdownSnippetSyntax # :nodoc:
  HOLDER = "Kerrick Long"
  LICENSE = "MIT-0"
  EXCLUDED = [
    "doc/contributors/v1.0.0_blockers.md",
    "doc/contributors/upstream_requests/tab_rects.md",
    "doc/contributors/upstream_requests/title_rects.md",
  ].freeze
  SYNC_START = /<!--\s*SYNC:START/
  SYNC_END = /<!--\s*SYNC:END/

  def extensions
    %w[md]
  end

  def tracked_patterns
    ["*.md"]
  end

  def excludes?(path)
    EXCLUDED.any? { |excluded| path.end_with?(excluded) }
  end

  def pending?(lines)
    regions, removals = scan(lines, first_pass: true)
    regions.any? || removals.any?
  end

  # Without the wrappers someone else's tooling wrote, so the code they held
  # can be wrapped again.
  def cleaned(lines)
    _, removals = scan(lines, first_pass: true)
    lines = lines.dup
    removals.sort_by { |first, _| -first }.each do |first, last|
      lines.delete_at(last)
      (opening_end(lines, first) - first + 1).times { lines.delete_at(first) }
    end
    lines
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

  def snippets_in(lines)
    regions, = scan(lines, first_pass: false)
    regions
  end

  def opening(_snippet, year)
    # REUSE-IgnoreStart
    [
      "<!-- SPDX-SnippetBegin -->\n",
      "<!--\n",
      "  SPDX-FileCopyrightText: #{year} #{HOLDER}\n",
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

  # The first pass leaves wrappers it recognizes alone and marks the rest for
  # removal. The second, after removal, skips every wrapper.
  private def scan(lines, first_pass:)
    document = MarkdownDocument.new(lines)
    regions = []
    removals = []
    index = 0
    while index < lines.length
      if lines[index].include?("SPDX-SnippetBegin")
        finish = index.upto(lines.length - 1).find { |later| lines[later].include?("SPDX-SnippetEnd") }
        if !first_pass
          index = (finish || lines.length) + 1
          next
        elsif finish
          removals << [index, finish] unless ours?(lines, index)
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

  private def ours?(lines, begin_line)
    header = lines[(begin_line + 1)..].take_while { |line| !line.include?("-->") }
    # REUSE-IgnoreStart
    header.any? { |line| line.include?(HOLDER) && line.include?("SPDX-FileCopyrightText") } &&
      header.any? { |line| line.include?("MIT-0") && line.include?("SPDX-License-Identifier") }
    # REUSE-IgnoreEnd
  end
end
