# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "rdoc_comment"
require_relative "snippet"
require_relative "snippet_opening"
require_relative "wrapped_snippet"

# The SPDX wrapper sits between #-- and #++ so RDoc leaves it out of the
# docs.
class RdocSnippetSyntax # :nodoc:
  LICENSE = "MIT-0"

  def extensions
    %w[rb]
  end

  def tracked_patterns
    ["*.rb"]
  end

  # Existing wrappers with their copyright notices under the snippet tag,
  # without the blank lines that once followed their code inside them, and
  # only around text RDoc shows as code.
  def cleaned(lines)
    in_tags = false
    tagged = lines.map do |line|
      in_tags = true if line.match?(/^\s*# SPDX-SnippetBegin\s*$/)
      cleaned_line = in_tags ? Snippet.tag(line) : line
      in_tags = false if line.match?(/^\s*#\+\+\s*$/)
      cleaned_line
    end
    without_wrappers_around_prose(blanks_after_wrappers(tagged))
  end

  def license
    LICENSE
  end

  # A wrapper marks its own snippet, whatever RDoc makes of the code inside
  # it. RDoc finds the examples that have no wrapper yet.
  def snippets_in(lines)
    wrapped = wrapped_in(lines)
    bare = examples(lines).reject { |example| wrapped.any? { |snippet| snippet.covers?(example) } }
    (wrapped + bare).sort_by(&:first)
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
    RdocComment.all_in(lines).flat_map(&:examples)
  end

  # The code between each SnippetBegin's #++ and its SnippetEnd's #--.
  private def wrapped_in(lines)
    lines.each_index.filter_map do |index|
      next unless lines[index].match?(/^\s*# SPDX-SnippetBegin\s*$/)

      prefix = lines[index][/\A\s*/]
      opened = (index + 1).upto(lines.length - 1).find { |line| lines[line].match?(/^#{Regexp.escape(prefix)}#\+\+\s*$/) }
      ended = opened && (opened + 1).upto(lines.length - 1).find { |line| lines[line].match?(/^\s*# SPDX-SnippetEnd\s*$/) }
      next unless ended && ended - 2 > opened

      snippet = Snippet.around(opened + 1, ended - 2, prefix:)
      WrappedSnippet.new(snippet:, opening: SnippetOpening.in(lines, index - 1, opened))
    end
  end

  # Wrappers once went around every indented comment, list items' text
  # included. A wrapper whose lines RDoc shows as prose comes off.
  private def without_wrappers_around_prose(lines)
    code = examples(lines).map(&:first)
    prose = wrapped_in(lines).reject { |wrapped| code.include?(wrapped.first) }
    prose.reverse_each.with_object(lines.dup) do |wrapped, unwrapped|
      ended = wrapped.snippet.last + 1
      unwrapped.slice!(ended..(ended + 2))
      unwrapped.slice!(wrapped.opening.span)
    end
  end

  # Blank comment lines after an example aren't part of it, as RDoc reads it.
  private def blanks_after_wrappers(lines)
    lines = lines.dup
    lines.each_index do |index|
      next unless lines[index].match?(/^\s*#--\s*$/) && lines[index + 1]&.match?(/^\s*# SPDX-SnippetEnd\s*$/)

      first_blank = index
      first_blank -= 1 while first_blank.positive? && lines[first_blank - 1].match?(/^\s*#\s*$/)
      lines.insert(first_blank + 3, *lines.slice!(first_blank...index)) if first_blank < index
    end
    lines
  end
end
