# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "date"
require "rdoc"

# Manages the Unreleased section of a changelog.
#
# Changelogs accumulate changes under an Unreleased heading. During a release,
# this section becomes a dated version entry. Parsing and transforming it by
# hand is tedious.
#
# This class extracts the Unreleased section from markdown. It transforms it
# into a versioned section. It generates commit message bodies.
#
# Use it during release preparation.
class UnreleasedSection
  # Regex to match the Unreleased section.
  PATTERN = /^(## \[Unreleased\].*?)(?=## \[\d)/m

  # Parses the Unreleased section from changelog content.
  #
  # [content] The full changelog text.
  def self.parse(content)
    match = content.match(PATTERN)
    new(match[1].strip) if match
  end

  # Returns a fresh Unreleased section with standard headings.
  def self.fresh
    new("## [Unreleased]\n\n### Added\n\n### Changed\n\n### Fixed\n\n### Removed")
  end

  # Creates a new UnreleasedSection.
  #
  # [content] The raw section text.
  def initialize(content)
    @content = content.dup
  end

  # Converts the section to a dated version entry.
  #
  # [new_version] The version string or SemVer.
  def as_version(new_version)
    date = Date.today.iso8601
    @content.sub(/^## \[Unreleased\]/, "## [#{new_version}] - #{date}")
  end

  # Returns the section as a string.
  def to_s
    @content
  end

  # Generates a commit message body from the changes.
  #
  # Strips markdown formatting and wraps lines to 72 characters.
  def commit_body
    formatter = Class.new { include RDoc::Text }.new
    @content
      .sub(/^## \[Unreleased\].*$/, "")
      .gsub(/^### (Added|Changed|Fixed|Removed)\n*$/, "")
      .gsub(/^- \*\*([^*]+)\*\*:/, '\1:')
      .gsub(/`([^`]+)`/, '\1')
      .strip
      .lines
      .map { |line| line.gsub(/^- /, "").strip }
      .reject(&:empty?)
      .map { |line| formatter.wrap(line, 72) }
      .join("\n\n")
  end

  # Returns all changelog entry lines (lines starting with "- ")
  def entries
    @content.lines.select { |line| line.strip.start_with?("- ") }.map(&:strip)
  end

  # Returns a new UnreleasedSection with entries removed that appear in the given list.
  def without_entries(entries_to_remove)
    return self if entries_to_remove.empty?

    new_lines = @content.lines.reject do |line|
      stripped = line.strip
      entries_to_remove.include?(stripped)
    end

    self.class.new(new_lines.join)
  end
end
