# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Usage: ruby tasks/license/snippets_md.rb [path...]
#
# With no paths, wraps the code blocks in every tracked Markdown file.

require_relative "markdown_snippet_syntax"
require_relative "snippet_file"

SnippetFile.tracked(ARGV, MarkdownSnippetSyntax.new).each(&:annotate) if __FILE__ == $PROGRAM_NAME
