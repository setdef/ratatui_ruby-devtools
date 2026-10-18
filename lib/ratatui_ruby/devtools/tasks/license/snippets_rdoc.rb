# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Usage: ruby tasks/license/snippets_rdoc.rb [path...]
#
# With no paths, wraps the RDoc examples in every tracked Ruby file.

require_relative "rdoc_snippet_syntax"
require_relative "snippet_file"

SnippetFile.tracked(ARGV, RdocSnippetSyntax.new).each(&:annotate) if __FILE__ == $PROGRAM_NAME
