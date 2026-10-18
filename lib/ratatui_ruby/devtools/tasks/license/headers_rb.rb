# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Usage: ruby tasks/license/headers_rb.rb [path...]
#
# With no paths, annotates every tracked Ruby and RBS file in the usual directories.

require_relative "licensed_file"
require_relative "ruby_header_syntax"

LicensedFile.tracked(ARGV, RubyHeaderSyntax.new).each(&:annotate) if __FILE__ == $PROGRAM_NAME
