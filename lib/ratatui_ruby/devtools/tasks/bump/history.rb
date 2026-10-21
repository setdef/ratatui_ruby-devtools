# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Manages the versioned history section of a changelog.
#
# Changelogs contain past version entries below the Unreleased section. During
# a release, new version entries prepend to this history. Manipulating it
# manually risks corruption.
#
# This class extracts history from the changelog. It prepends new version
# entries. It serializes back to markdown.
#
# Use it during release preparation.
class History
  # Parses the history section from changelog content.
  #
  # [content] The full changelog text.
  # [header_length] Length of the header section.
  # [unreleased_length] Length of the Unreleased section.
  # [links] The changelog's Links, where the history ends.
  def self.parse(content, header_length, unreleased_length, links)
    start = header_length + unreleased_length
    text = "#{content[start...(links.start_in(content))].strip}\n"
    new(text)
  end

  # Creates a new History.
  #
  # [content] The raw history text.
  def initialize(content)
    @content = content.dup
  end

  # Adds a new versioned section to the beginning of history.
  #
  # [section] The version section text to prepend.
  def add(section)
    @content = "#{"#{section}\n\n#{@content}".strip}\n"
    nil
  end

  # Returns the history as a string.
  def to_s
    @content
  end
end
