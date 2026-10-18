# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Represents a semantic version number.
#
# Version numbers have three segments: major, minor, patch. Incrementing one
# resets the following segments to zero. Parsing strings by hand is tedious.
#
# This class parses version strings and computes the next version for any
# segment. It follows the Semantic Versioning 2.0.0 specification.
#
# Use it to bump versions in rake tasks.
#
# === Example
#
#   SemVer.parse("1.2.3").next(:minor).to_s  # => "1.3.0"
#
# See https://semver.org/spec/v2.0.0.html
class SemVer
  # The valid segment names for version bumping.
  SEGMENTS = [:major, :minor, :patch].freeze

  # Parses a version string into a SemVer instance.
  #
  # [string] A version string like <tt>"1.2.3"</tt>.
  def self.parse(string)
    require "rubygems"
    # Extract prerelease suffix (e.g., "-beta.1", "-alpha.2", "-rc.1")
    base, prerelease = string.split("-", 2)
    segments = Gem::Version.new(base).segments.fill(0, 3).first(3)
    new(segments, prerelease:)
  end

  # Creates a new SemVer from an array of segments.
  #
  # [segments] An array of three integers: <tt>[major, minor, patch]</tt>.
  def initialize(segments, prerelease: nil)
    @segments = segments
    @prerelease = prerelease
  end

  # Returns the next version after bumping the given segment.
  #
  # Bumping a segment resets all following segments to zero.
  #
  # [segment] One of <tt>:major</tt>, <tt>:minor</tt>, or <tt>:patch</tt>.
  def next(segment)
    index = SEGMENTS.index(segment)
    raise ArgumentError, "Invalid segment: #{segment}" unless index

    new_segments = @segments.dup
    new_segments[index] += 1
    new_segments.fill(0, (index + 1)..2)

    SemVer.new(new_segments)
  end

  # Returns the version as a string.
  def to_s
    base = @segments.join(".")
    @prerelease ? "#{base}-#{@prerelease}" : base
  end
end
