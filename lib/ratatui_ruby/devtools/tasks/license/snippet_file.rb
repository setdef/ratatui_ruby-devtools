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

  # Brings the file's snippets up to date and says what changed.
  def annotate
    # Binary mode keeps the file's own line endings, which text mode on
    # Windows would turn into CRLF.
    text = File.read(path, mode: "rb", encoding: "UTF-8")
    revision = SnippetRevision.new(path:, text:, syntax:, author:).run
    File.write(path, revision.text, mode: "wb") if revision.changed?
    revision.messages
  end
end
