# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Usage: ruby tasks/license/headers_md.rb [path...]
#
# With no paths, annotates every tracked Markdown file.

require_relative "licensed_file"
require_relative "markdown_header_syntax"

LicensedFile.tracked(ARGV, MarkdownHeaderSyntax.new).each(&:annotate) if __FILE__ == $PROGRAM_NAME
