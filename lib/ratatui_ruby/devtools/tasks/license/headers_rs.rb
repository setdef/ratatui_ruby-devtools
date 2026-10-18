# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Usage: ruby tasks/license/headers_rs.rb [path...]
#
# With no paths, annotates every tracked Rust file in ext/.

require_relative "licensed_file"
require_relative "rust_header_syntax"

LicensedFile.tracked(ARGV, RustHeaderSyntax.new).each(&:annotate) if __FILE__ == $PROGRAM_NAME
