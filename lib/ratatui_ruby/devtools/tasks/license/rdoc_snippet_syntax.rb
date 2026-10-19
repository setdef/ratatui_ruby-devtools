# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "snippet"
require_relative "snippet_opening"
require_relative "wrapped_snippet"

# RDoc examples are comment lines indented three or more spaces. The SPDX
# wrapper sits between #-- and #++ so RDoc leaves it out of the docs.
class RdocSnippetSyntax # :nodoc:
  LICENSE = "MIT-0"
  EXAMPLE = /^(\s*)#(   +)(\S.*)$/

  def extensions
    %w[rb]
  end

  def tracked_patterns
    ["*.rb"]
  end

  def excludes?(_path)
    false
  end

  # Existing wrappers with their copyright notices under the snippet tag.
  def cleaned(lines)
    in_tags = false
    lines.map do |line|
      in_tags = true if line.match?(/^\s*# SPDX-SnippetBegin\s*$/)
      cleaned_line = in_tags ? Snippet.tag(line) : line
      in_tags = false if line.match?(/^\s*#\+\+\s*$/)
      cleaned_line
    end
  end

  def license
    LICENSE
  end

  # Every example, with the opening of those already wrapped. A one-line
  # example is too small to count.
  def snippets_in(lines)
    examples(lines).filter_map do |snippet|
      next snippet unless wrapped?(lines, snippet)

      opening = opening_of(lines, snippet)
      WrappedSnippet.new(snippet:, opening:) if opening
    end
  end

  def opening(snippet, copyrights)
    prefix = snippet.prefix
    # REUSE-IgnoreStart
    [
      "#{prefix}#--\n",
      "#{prefix}# SPDX-SnippetBegin\n",
      *copyrights.map { |copyright| "#{prefix}# #{Snippet::COPYRIGHT_TAG}: #{copyright}\n" },
      "#{prefix}# SPDX-License-Identifier: #{LICENSE}\n",
      "#{prefix}#++\n",
    ]
    # REUSE-IgnoreEnd
  end

  def closing(snippet)
    prefix = snippet.prefix
    # REUSE-IgnoreStart
    [
      "#{prefix}#--\n",
      "#{prefix}# SPDX-SnippetEnd\n",
      "#{prefix}#++\n",
    ]
    # REUSE-IgnoreEnd
  end

  private def examples(lines)
    examples = []
    index = 0
    while index < lines.length
      prefix = lines[index][EXAMPLE, 1]
      next index += 1 unless prefix

      last = last_line(lines, index, prefix)
      example = Snippet.around(index, last, prefix:)
      examples << example if last > index && code?(lines, example)
      index = last + 1
    end
    examples
  end

  # The #-- to #++ block just above a wrapped example.
  private def opening_of(lines, snippet)
    closing = snippet.first - 1
    start = (closing - 1).downto(0).find { |index| lines[index].match?(/^#{Regexp.escape(snippet.prefix)}#--\s*$/) }
    SnippetOpening.in(lines, start, closing) if start
  end

  # An example runs on through indented and blank comment lines.
  private def last_line(lines, first, prefix)
    continuation = /^#{Regexp.escape(prefix)}#(   +|\s*$)/
    last = first
    last += 1 while last + 1 < lines.length && lines[last + 1].match?(continuation)
    last
  end

  private def code?(lines, snippet)
    snippet.lines_in(lines).any? { |line| line.match?(/^#{Regexp.escape(snippet.prefix)}#   +\S/) }
  end

  private def wrapped?(lines, snippet)
    snippet.first >= 1 && lines[snippet.first - 1].match?(/^#{Regexp.escape(snippet.prefix)}#\+\+\s*$/)
  end
end
