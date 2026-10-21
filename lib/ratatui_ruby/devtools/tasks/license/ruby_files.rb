# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "licensed_file"
require_relative "rdoc_snippet_syntax"
require_relative "ruby_header_syntax"
require_relative "snippet_file"

class RubyFiles < Data.define(:files) # :nodoc:
  def self.changed(repository, licensing)
    new(files: LicensedFile.changed(RubyHeaderSyntax.new(licensing), repository:))
  end

  def label
    "Ruby"
  end

  def count
    files.count
  end

  def license
    files.flat_map(&:annotate) + library.flat_map(&:annotate)
  end

  # RDoc examples only appear in the documented library.
  private def library
    syntax = RdocSnippetSyntax.new
    files.select { |file| file.path.start_with?("lib/") && file.path.end_with?(".rb") }
      .map { |file| SnippetFile.new(path: file.path, syntax:, author: file.author) }
  end
end
