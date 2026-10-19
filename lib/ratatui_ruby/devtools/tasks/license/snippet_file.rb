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
      contributions = blame.contributions([snippet.blame_range], uncommitted_by: author)
      if snippet.opening
        renew(lines, snippet, contributions)
      else
        wrap(lines, snippet, contributions)
      end
    end

    updated = lines.join
    return if updated == original

    File.write(path, updated)
    wrapped = snippets.count { |snippet| !snippet.opening }
    message = if wrapped.zero?
      "Updated: #{path}"
    else
      "Updated: #{path} (#{wrapped} code block(s))"
    end
    puts message
  end

  private def wrap(lines, snippet, contributions)
    copyrights = contributions.map { |contribution| Copyright.of(contribution) }.sort_by(&:holder)
    lines.insert(snippet.last + 1, *syntax.closing(snippet))
    lines.insert(snippet.first, *syntax.opening(snippet, copyrights))
  end

  private def renew(lines, snippet, contributions)
    opening = snippet.opening
    renewed = opening.header.renewed(contributions, syntax.license)
    return if renewed == opening.header

    lines[opening.span] = syntax.opening(snippet, renewed.copyrights)
  end
end
