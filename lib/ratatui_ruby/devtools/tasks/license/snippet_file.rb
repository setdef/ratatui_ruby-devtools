# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "../bump/repository"
require_relative "blame"
require_relative "copyright"

class SnippetFile < Data.define(:path, :syntax, :author) # :nodoc:
  def self.tracked(paths, syntax, repository: Repository.new)
    files = repository.tracked_files_for(paths, syntax)
    return [] if files.empty?

    author = repository.author
    files.map { |path| new(path:, syntax:, author:) }
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
      lines.insert(snippet.last + 1, *syntax.closing(snippet))
      lines.insert(snippet.first, *syntax.opening(snippet, copyrights(blame, snippet)))
    end

    updated = lines.join
    return if updated == original

    File.write(path, updated)
    puts snippets.empty? ? "Updated: #{path}" : "Updated: #{path} (#{snippets.length} code block(s))"
  end

  private def copyrights(blame, snippet)
    blame.contributions([snippet.blame_range], uncommitted_by: author)
      .map { |contribution| Copyright.new(year: contribution.year, holder: contribution.author.to_s) }
      .sort_by(&:holder)
  end
end
