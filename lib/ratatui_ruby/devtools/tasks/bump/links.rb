# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "no_links"

# Manages the version comparison links at the botton of the changelog.
#
# Release automation needs to update links. Manually calculating git diff URLs
# for every release is tedious and error-prone. SourceHut does not have
# standard comparison views, complicating matters further.
#
# This class manages the collection of links. It parses them from the markdown.
# It generates the correct tree links for SourceHut. It properly shifts the
# "Unreleased" pointer.
#
# Use it to update the changelog during a release.
class Links
  # Regex to match the markdown links section.
  #
  # Changelogs end with reference-style links. Scanning the whole document is
  # wasteful. This pattern finds where the links begin.
  PATTERN = /^(\[Unreleased\]: .*)$/m

  # Regex to extract the base URL from the Unreleased link.
  #
  # New version links derive from the Unreleased URL structure. Parsing the
  # URL components enables programmatic link generation.
  UNRELEASED_PATTERN = %r{^\[Unreleased\]: (.*?/refs/)HEAD$}

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
  # the just-released version pointing to its specific tag.
  #
  # [version] String. The new version number (e.g., <tt>"0.5.0"</tt>).
  def release(version)
    return unless base_url

    new_unreleased = "[Unreleased]: #{base_url}HEAD" # .../HEAD
    new_version_link = "[#{version}]: #{base_url}v#{version}" # .../v1.0.0

    @text.sub!(UNRELEASED_PATTERN, "#{new_unreleased}\n#{new_version_link}")
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

  # The base URL for the repository's references.
  private def base_url
    match = @text.match(UNRELEASED_PATTERN)
    match[1] if match
  end
end
