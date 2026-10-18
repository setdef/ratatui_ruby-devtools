# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "license_script"
require_relative "licensed_file"
require_relative "ruby_header_syntax"

class RubyFiles < Data.define(:files) # :nodoc:
  def self.changed(repository)
    new(files: LicensedFile.changed(RubyHeaderSyntax.new, repository:))
  end

  def label
    "Ruby"
  end

  def count
    files.count
  end

  def license
    files.each(&:annotate)
    LicenseScript.new("snippets_rdoc.rb").run(library) unless library.empty?
  end

  # RDoc examples only appear in the documented library.
  private def library
    files.map(&:path).select { |path| path.start_with?("lib/") && path.end_with?(".rb") }
  end
end
