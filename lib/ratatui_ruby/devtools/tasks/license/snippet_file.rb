# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "../bump/repository"
require_relative "blame"

class SnippetFile < Data.define(:path, :syntax) # :nodoc:
  def self.tracked(paths, syntax, repository: Repository.new)
    repository.tracked_files_for(paths, syntax).map { |path| new(path:, syntax:) }
  end

  def annotate
    return if syntax.excludes?(path)

    original = File.read(path)
    lines = syntax.cleaned(original.lines)
    snippets = syntax.snippets_in(lines)

    # Blame reads the cleaned lines the snippets were found in, not the file
    # on disk, and wrapping from the last snippet back keeps the earlier ones
    # where blame found them.
    blame = Blame.new(path:, contents: lines.join)
    snippets.reverse_each do |snippet|
      year = blame.latest_year(snippet.blame_range)
      lines.insert(snippet.last + 1, *syntax.closing(snippet))
      lines.insert(snippet.first, *syntax.opening(snippet, year))
    end

    updated = lines.join
    return if updated == original

    File.write(path, updated)
    puts "Updated: #{path} (#{snippets.length} code block(s))"
  end
end
