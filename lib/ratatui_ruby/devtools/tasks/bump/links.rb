# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "github_project"
require_relative "no_links"
require_relative "source_hut_project"

# Manages the version comparison links at the botton of the changelog.
#
# Release automation needs to update links. Manually calculating the URLs
# for every release is tedious and error-prone, and each forge shapes them
# differently.
#
# This class manages the collection of links. It parses them from the markdown.
# It finds the project from the "Unreleased" link and asks it for the new
# links, on GitHub or SourceHut. It properly shifts the "Unreleased" pointer.
#
# Use it to update the changelog during a release.
class Links
  # Regex to match the markdown links section.
  #
  # Changelogs end with reference-style links. Scanning the whole document is
  # wasteful. This pattern finds where the links begin.
  PATTERN = /^(\[Unreleased\]: .*)$/m

  # Regex to extract the URL of the Unreleased link.
  #
  # New version links derive from the project it links into.
  UNRELEASED_PATTERN = /^\[Unreleased\]: (\S+)$/

  # The forges whose links a release can write.
  PROJECTS = [GitHubProject, SourceHutProject].freeze

  # Creates a Links object from the full markdown content.
  #
  # [content] String. The full text of the changelog.
  def self.from_markdown(content)
    match = content.match(PATTERN)
    match ? new(match[1].strip) : NoLinks.new
  end

  # Returns the raw text of the links.
  attr_reader :text

  # Creates a new Links object.
  #
  # [text] String. The raw text of the links section.
  def initialize(text)
    @text = text.dup
  end

  # Releases a new version.
  #
  # Updates the "Unreleased" link to point to the new head. Adds a new link for
  # the just-released version pointing to its specific tag. Warns instead when
  # the "Unreleased" link isn't into a GitHub or SourceHut project.
  #
  # [version] String. The new version number (e.g., <tt>"0.5.0"</tt>).
  def release(version)
    link = @text[UNRELEASED_PATTERN, 1]
    project = PROJECTS.lazy.filter_map { |forge| forge.linked_from(link) }.first
    unless project
      warn "The changelog's Unreleased link, #{link}, isn't into a GitHub or SourceHut project, " \
        "so #{version} has no link. Add one by hand."
      return self
    end

    @text.sub!(UNRELEASED_PATTERN, "[Unreleased]: #{project.unreleased(version)}\n[#{version}]: #{project.release(version)}")
    self
  end

  # Returns where the links begin in +content+, which is where the history
  # before them ends.
  #
  # [content] String. The full text of the changelog.
  def start_in(content)
    content.index(@text)
  end

  # Returns the links as the changelog ends with them, after a blank line.
  def footer
    "\n#{@text}\n"
  end

  # Returns the string representation of the links.
  def to_s
    @text
  end
end
