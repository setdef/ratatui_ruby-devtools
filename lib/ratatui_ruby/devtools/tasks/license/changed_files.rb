# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "../bump/repository"
require_relative "markdown_files"
require_relative "ruby_files"
require_relative "rust_files"

class ChangedFiles < Data.define(:repository) # :nodoc:
  LANGUAGES = [MarkdownFiles, RubyFiles, RustFiles].freeze

  # Licenses what changed and says what it did.
  def license
    languages = LANGUAGES.map { |language| language.changed(repository) }
    changed = languages.reject { |language| language.count.zero? }
    return ["No changed #{sentence(languages.map(&:label))} files to process"] if changed.empty?

    changed.flat_map do |language|
      ["Processing #{language.count} changed #{language.label} file(s)...", *language.license]
    end
  end

  private def sentence(words)
    "#{words[0...-1].join(', ')}, or #{words.last}"
  end
end
