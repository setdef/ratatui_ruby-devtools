# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Shared utility for detecting contributors from git blame and Co-Authored-By trailers.
#
# This module provides methods to:
# - Get all contributors (authors and co-authors) who touched specific lines
# - Track the latest year each contributor touched those lines
# - Parse Co-Authored-By trailers from commit messages

require "open3"
require "date"

# Extracts contributor information from git history.
#
# License headers need accurate copyright years and contributor names. Git
# blame provides line-level authorship. Commit messages contain Co-Authored-By
# trailers. Combining these sources manually is tedious.
#
# This module queries git blame and parses commit messages. It returns
# contributor names with their latest modification years. Use it when
# generating or updating SPDX headers.
module LicenseUtils
  # A contributor with their latest modification year.
  #
  # [name] The contributor's display name.
  # [email] The contributor's email address.
  # [year] The most recent year they modified the file.
  class Contributor < Data.define(:name, :email, :year)
    # The name and email the way git writes an author.
    #
    # Copyright holders are matched against this text.
    def to_s
      "#{name} <#{email}>"
    end
  end

  class << self
    # Get all contributors who touched lines in a file (or range of lines).
    # Returns a Hash of { "Name <email>" => year } mapping each contributor to their latest year.
    #
    # This considers both the commit author AND any Co-Authored-By trailers in commit messages.
    def get_contributors_for_lines(filepath, start_line = nil, end_line = nil)
      blame_cmd = if start_line && end_line
        %W[git blame -L #{start_line},#{end_line} --porcelain -- #{filepath}]
      else
        %W[git blame --porcelain -- #{filepath}]
      end

      output, _status = Open3.capture2(*blame_cmd)

      contributors = {}  # "Name <email>" => year
      commit_cache = {}  # commit_hash => { year:, author:, co_authors: [] }

      current_commit = nil

      output.each_line do |line|
        if line =~ /^([a-f0-9]{40})/
          current_commit = $1
        elsif line =~ /^author (.+)$/
          commit_cache[current_commit] ||= {}
          commit_cache[current_commit][:author_name] = $1
        elsif line =~ /^author-mail <(.+)>$/
          commit_cache[current_commit] ||= {}
          commit_cache[current_commit][:author_email] = $1
        elsif line =~ /^author-time (\d+)$/
          commit_cache[current_commit] ||= {}
          timestamp = $1.to_i
          commit_cache[current_commit][:year] = Time.at(timestamp).year
        end
      end

      # Now fetch co-authors for each unique commit
      commit_cache.each do |commit_hash, data|
        next if commit_hash == "0" * 40 # Skip uncommitted lines

        # Get commit message for Co-Authored-By parsing
        msg_output, _status = Open3.capture2("git", "log", "-1", "--format=%B", commit_hash)
        co_authors = parse_co_authors(msg_output)
        data[:co_authors] = co_authors

        # Add author
        if data[:author_name] && data[:author_email]
          key = "#{data[:author_name]} <#{data[:author_email]}>"
          year = data[:year] || Date.today.year
          contributors[key] = [contributors[key] || 0, year].max
        end

        # Add co-authors with same year as commit
        co_authors.each do |ca|
          key = "#{ca[:name]} <#{ca[:email]}>"
          year = data[:year] || Date.today.year
          contributors[key] = [contributors[key] || 0, year].max
        end
      end

      contributors
    end

    # Every contributor who touched a file, with the latest year each touched
    # it.
    #
    # [filepath] Path to the file.
    # [line_ranges] Pairs of first and last line numbers, counting from 1, to
    #   limit the search to. Omit it to search the whole file.
    def contributors(filepath, line_ranges = nil)
      years = if line_ranges
        line_ranges.each_with_object({}) do |(first, last), merged|
          get_contributors_for_lines(filepath, first, last).each do |contributor, year|
            merged[contributor] = [merged[contributor] || 0, year].max
          end
        end
      else
        get_contributors_for_lines(filepath)
      end
      years.filter_map do |contributor, year|
        Contributor.new(name: $1.strip, email: $2.strip, year:) if contributor =~ /^(.+?)\s*<(.+)>$/
      end
    end

    # Get all contributors EXCEPT you, with their latest years.
    # Returns array of { name:, email:, year: }
    def get_other_contributors(filepath, your_identifiers, start_line = nil, end_line = nil)
      contributors = get_contributors_for_lines(filepath, start_line, end_line)

      others = []
      contributors.each do |contributor, year|
        next if your_identifiers.any? { |id| contributor.include?(id) }

        # Parse "Name <email>" format
        if contributor =~ /^(.+?)\s*<(.+)>$/
          others << { name: $1.strip, email: $2.strip, year: }
        end
      end

      others
    end

    private def parse_co_authors(message)
      co_authors = []

      message.each_line do |line|
        # Match "Co-Authored-By: Name <email>" (case insensitive)
        if line =~ /^Co-Authored-By:\s*(.+?)\s*<(.+?)>\s*$/i
          co_authors << { name: $1.strip, email: $2.strip }
        end
      end

      co_authors
    end
  end
end
