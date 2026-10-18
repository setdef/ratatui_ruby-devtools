# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "license_script"

class MarkdownFiles < Data.define(:paths) # :nodoc:
  def self.changed(repository)
    new(paths: repository.changed_files.select { |path| path.end_with?(".md") })
  end

  def label
    "Markdown"
  end

  def count
    paths.count
  end

  def license
    LicenseScript.new("headers_md.rb").run(paths)
    LicenseScript.new("snippets_md.rb").run(paths)
  end
end
