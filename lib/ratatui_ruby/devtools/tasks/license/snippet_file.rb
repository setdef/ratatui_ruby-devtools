# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "../bump/repository"
require_relative "snippet_revision"

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
    revision = SnippetRevision.new(path:, text: original, syntax:, author:).run
    return if revision.text == original

    File.write(path, revision.text)
    wrapped = revision.snippets.count(&:bare?)
    message = if wrapped.zero?
      "Updated: #{path}"
    else
      "Updated: #{path} (#{wrapped} code block(s))"
    end
    puts message
  end
end
