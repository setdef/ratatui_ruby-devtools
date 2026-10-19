# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "date"
require "open3"
require_relative "contribution"

# Who last touched each line of a file, counting Co-Authored-By trailers as
# well as commit authors. Given +contents+, it blames that text against the
# file's history instead of what's on disk, so line numbers can refer to
# lines that are about to be written.
class Blame < Data.define(:path, :contents) # :nodoc:
  UNCOMMITTED = "0" * 40

  def initialize(path:, contents: nil)
    super
  end

  # Each author once, with the latest year they touched the lines.
  # [line_ranges] Pairs of first and last line numbers, counting from 1.
  #   Omit them to blame the whole file.
  # [uncommitted_by] The author to credit, this year, for lines not yet
  #   committed. Without one, those lines count for nobody.
  def contributions(line_ranges = nil, uncommitted_by: nil)
    found = (line_ranges || [nil]).flat_map { |range| contributions_in(range, uncommitted_by) }
    found.group_by(&:author).map { |_, same| same.max_by(&:year) }
  end

  private def contributions_in(range, uncommitted_by)
    # A file git doesn't track yet is uncommitted throughout.
    commits = commits_in(range) || { UNCOMMITTED => {} }
    commits.flat_map do |commit, author|
      if commit == UNCOMMITTED
        next [] unless uncommitted_by

        next [Contribution.new(author: uncommitted_by, year: Date.today.year)]
      end

      year = author[:year] || Date.today.year
      authors = (author[:name] && author[:email]) ? [[author[:name].strip, author[:email].strip]] : []
      (authors + co_authors_of(commit)).map do |name, email|
        Contribution.new(author: Repository::Author.new(name:, email:), year:)
      end
    end
  end

  private def commits_in(range)
    command = %w[git blame --porcelain]
    command += ["-L", range.join(",")] if range
    command += ["--contents", "-"] if contents
    output, status = Open3.capture2(*command, "--", path, stdin_data: contents.to_s, err: File::NULL)
    return unless status.success?

    commits = {}
    commit = nil
    output.each_line do |line|
      case line
      when /^([a-f0-9]{40})/ then commit = $1
      when /^author (.+)$/ then (commits[commit] ||= {})[:name] = $1
      when /^author-mail <(.+)>$/ then (commits[commit] ||= {})[:email] = $1
      when /^author-time (\d+)$/ then (commits[commit] ||= {})[:year] = Time.at($1.to_i).year
      end
    end
    commits
  end

  private def co_authors_of(commit)
    message, _status = Open3.capture2("git", "log", "-1", "--format=%B", commit)
    message.scan(/^Co-Authored-By:\s*(.+?)\s*<(.+?)>\s*$/i).map { |name, email| [name.strip, email.strip] }
  end
end
