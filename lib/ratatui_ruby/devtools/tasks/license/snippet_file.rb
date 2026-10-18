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
    lines = File.read(path).lines
    snippets = syntax.snippets_in(lines)
    return if snippets.empty?

    # Wrapping from the last snippet back keeps the earlier ones' lines where
    # blame found them.
    blame = Blame.new(path)
    snippets.reverse_each do |snippet|
      year = blame.latest_year(snippet.blame_range)
      lines.insert(snippet.last + 1, *syntax.closing(snippet))
      lines.insert(snippet.first, *syntax.opening(snippet, year))
    end

    File.write(path, lines.join)
    puts "Updated: #{path} (#{snippets.length} code block(s))"
  end
end
