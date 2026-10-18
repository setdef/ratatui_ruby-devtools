# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "../bump/repository"
require_relative "license_utils"
require_relative "spdx_header"

class LicensedFile < Data.define(:path, :syntax, :author) # :nodoc:
  def self.changed(syntax, repository: Repository.new)
    files = repository.changed_files.select do |path|
      syntax.extensions.include?(File.extname(path).delete_prefix(".")) &&
        syntax.directories.any? { |directory| path.start_with?("#{directory}/") }
    end
    of(files, syntax, repository)
  end

  def self.tracked(paths, syntax, repository: Repository.new)
    files = if paths.empty?
      syntax.directories.flat_map do |directory|
        syntax.extensions.flat_map do |extension|
          repository.tracked_files("#{directory}/*.#{extension}") +
            repository.tracked_files("#{directory}/**/*.#{extension}")
        end
      end.uniq
    else
      paths.flat_map do |path|
        next path unless File.directory?(path)

        syntax.extensions.flat_map { |extension| repository.tracked_files("#{path}/**/*.#{extension}") }
      end
    end
    of(files, syntax, repository)
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
    contributors = LicenseUtils.contributors(path)
    existing, end_line = syntax.header_in(lines)

    if existing
      renewed = existing.renewed(author, contributors, license)
      return if renewed == existing

      body = lines.drop(end_line + 1).drop_while { |line| line.strip.empty? }
      File.write(path, syntax.replaced(renewed, lines, body))
      puts "Updated: #{path}"
    else
      File.write(path, syntax.added(SpdxHeader.of(author, contributors, license), lines))
      puts "Added header: #{path}"
    end
  end

  private def license
    case path
    when %r{^(lib|sig/ratatui_ruby|ext|test)/}
      "LGPL-3.0-or-later"
    when %r{^(examples|sig/examples)/(widget_|verify_)}
      "MIT-0"
    else
      "AGPL-3.0-or-later"
    end
  end
end
