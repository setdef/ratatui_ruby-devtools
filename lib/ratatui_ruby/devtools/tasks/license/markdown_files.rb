# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "licensed_file"
require_relative "markdown_header_syntax"
require_relative "markdown_snippet_syntax"
require_relative "snippet_file"

class MarkdownFiles < Data.define(:files) # :nodoc:
  def self.changed(repository)
    new(files: LicensedFile.changed(MarkdownHeaderSyntax.new, repository:))
  end

  def label
    "Markdown"
  end

  def count
    files.count
  end

  def license
    files.each(&:annotate)
    syntax = MarkdownSnippetSyntax.new
    files.each { |file| SnippetFile.new(path: file.path, syntax:).annotate }
  end
end
