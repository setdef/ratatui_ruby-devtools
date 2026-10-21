# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "links"
require_relative "unreleased_section"
require_relative "history"
require_relative "header"

# Manages the project's CHANGELOG.md file.
#
# Changelogs track user-facing changes. During a release, the Unreleased
# section becomes a versioned section. Links update. The Unreleased section
# resets. Doing this by hand invites errors.
#
# This class orchestrates the changelog update. It parses the sections, moves
# content, updates links, and writes the result. One call. Clean changelog.
#
# Use it during version bumps to update the release notes.
class Changelog
  # Creates a new Changelog manager.
  #
  # [path] The path to the changelog file. Defaults to <tt>CHANGELOG.md</tt>.
  def initialize(path: "CHANGELOG.md")
    @path = path
  end

  # Releases a new version in the changelog.
  #
  # Moves unreleased changes to a dated version section. Resets the Unreleased
  # section. Updates the comparison links.
  #
  # [new_version] The SemVer or version string to release.
  def release(new_version)
    content = File.read(@path)

    header = Header.parse(content)
    unreleased = UnreleasedSection.parse(content)
    links = Links.from_markdown(content)

    raise "Could not parse CHANGELOG.md" unless header && unreleased

    history = History.parse(content, header.length, unreleased.to_s.length, links)

    links.release(new_version)
    history.add(unreleased.as_version(new_version))

    File.write(@path, "#{header}#{UnreleasedSection.fresh}\n\n#{history}#{links.footer}")
    nil
  end

  # Removes entries from [Unreleased] that were released in the given version.
  # Used when creating a release branch from trunk.
  def prune_released_entries(released_entries)
    content = File.read(@path)

    header = Header.parse(content)
    unreleased = UnreleasedSection.parse(content)
    links = Links.from_markdown(content)

    raise "Could not parse CHANGELOG.md" unless header && unreleased

    history = History.parse(content, header.length, unreleased.to_s.length, links)

    pruned = unreleased.without_entries(released_entries)

    File.write(@path, "#{header}#{pruned}\n\n#{history}#{links.footer}")
    nil
  end

  # Imports a release section from another branch's changelog.
  # Adds the version section to history and dedupes from [Unreleased].
  # Uses "first wins" — if entry already deduped, doesn't re-add it.
  def import_release(version, release_changelog_content)
    release_section = extract_version_section(release_changelog_content, version)
    return unless release_section

    content = File.read(@path)

    header = Header.parse(content)
    unreleased = UnreleasedSection.parse(content)
    links = Links.from_markdown(content)

    raise "Could not parse CHANGELOG.md" unless header && unreleased

    history = History.parse(content, header.length, unreleased.to_s.length, links)

    # Add the release section to history (inserted in version order)
    history.add(release_section)
    links.release(version)

    # Dedupe from [Unreleased] (first-wins: if already gone, no-op)
    release_entries = release_section.lines.select { |l| l.strip.start_with?("- ") }.map(&:strip)
    pruned = unreleased.without_entries(release_entries)

    File.write(@path, "#{header}#{pruned}\n\n#{history}#{links.footer}")
    nil
  end

  # Generates a commit message for the release.
  #
  # Extracts the unreleased changes and formats them for a commit body.
  #
  # [version] The version being released.
  def commit_message(version)
    content = File.read(@path)
    unreleased = UnreleasedSection.parse(content)
    return nil unless unreleased

    "chore: release v#{version}\n\n#{unreleased.commit_body}"
  end

  private def extract_version_section(changelog_content, version)
    # Match the version heading and capture until the next version heading or links section
    pattern = /^## \[#{Regexp.escape(version.to_s)}\][^\n]*\n(.*?)(?=^## \[|\n\[Unreleased\]:)/m
    match = changelog_content.match(pattern)
    return nil unless match

    "## [#{version}]#{match[0].split("\n", 2).first.split(']', 2).last}\n#{match[1]}"
  end
end
