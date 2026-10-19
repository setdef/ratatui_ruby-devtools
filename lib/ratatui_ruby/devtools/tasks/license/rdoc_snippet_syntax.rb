# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "snippet"

# RDoc examples are comment lines indented three or more spaces. The SPDX
# wrapper sits between #-- and #++ so RDoc leaves it out of the docs.
class RdocSnippetSyntax # :nodoc:
  HOLDER = "Kerrick Long"
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

  def cleaned(lines)
    lines
  end

  # Examples not yet wrapped. A one-line example is too small to count.
  def snippets_in(lines)
    snippets = []
    index = 0
    while index < lines.length
      prefix = lines[index][EXAMPLE, 1]
      next index += 1 unless prefix

      last = last_line(lines, index, prefix)
      snippet = Snippet.around(index, last, prefix:)
      snippets << snippet if last > index && code?(lines, snippet) && !wrapped?(lines, snippet)
      index = last + 1
    end
    snippets
  end

  def opening(snippet, year)
    prefix = snippet.prefix
    # REUSE-IgnoreStart
    [
      "#{prefix}#--\n",
      "#{prefix}# SPDX-SnippetBegin\n",
      "#{prefix}# SPDX-FileCopyrightText: #{year} #{HOLDER}\n",
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
