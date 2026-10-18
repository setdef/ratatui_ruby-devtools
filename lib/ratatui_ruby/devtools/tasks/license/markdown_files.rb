# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "license_script"
require_relative "licensed_file"
require_relative "markdown_header_syntax"

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
    LicenseScript.new("snippets_md.rb").run(files.map(&:path))
  end
end
