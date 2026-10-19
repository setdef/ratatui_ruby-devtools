# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "../bump/repository"
require_relative "header_revision"

class LicensedFile < Data.define(:path, :syntax, :author) # :nodoc:
  def self.changed(syntax, repository: Repository.new)
    of(repository.changed_files.select { |path| syntax.covers?(path) }, syntax, repository)
  end

  def self.tracked(paths, syntax, repository: Repository.new)
    of(repository.tracked_files_for(paths, syntax), syntax, repository)
  end

  # Asking git for the author only when there are files keeps a run with
  # nothing to annotate working where git has no identity, as in CI.
  private_class_method def self.of(files, syntax, repository)
    return [] if files.empty?

    author = repository.author
    files.map { |file| new(path: file, syntax:, author:) }
  end

  def annotate
    lines = File.read(path).lines
    revision = HeaderRevision.new(path:, lines:, syntax:, author:)
    syntax.header_in(lines).revise(revision)
    return unless revision.text

    File.write(path, revision.text)
    puts revision.report
  end
end
