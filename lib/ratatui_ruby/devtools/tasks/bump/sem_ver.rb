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

  # Dot-separated prerelease identifiers. Numeric identifiers have no leading
  # zeroes.
  PRERELEASE = /\A(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*\z/

  # Parses a version string into a SemVer instance.
  #
  # Raises ArgumentError for a prerelease that isn't SemVer, such as
  # <tt>"1.0.0.beta.1"</tt> or <tt>"1.0.0-alpha.001"</tt>.
  #
  # [string] A version string like <tt>"1.2.3"</tt> or <tt>"1.0.0-rc.1"</tt>.
  def self.parse(string)
    require "rubygems"
    # Extract prerelease suffix (e.g., "-beta.1", "-alpha.2", "-rc.1")
    base, prerelease = string.split("-", 2)
    version = Gem::Version.new(base)
    if version.prerelease?
      raise ArgumentError, "#{string} is not SemVer. Put the prerelease after a hyphen, like 1.0.0-beta.1."
    end
    if prerelease && !prerelease.match?(PRERELEASE)
      raise ArgumentError, "#{string} has an invalid prerelease. Use dot-separated letters, digits, and hyphens, " \
        "with no leading zeroes in numbers, like 1.0.0-alpha.1."
    end

    segments = (version.segments + [0, 0, 0]).first(3)
    new(segments, prerelease:)
  end

  # Creates a new SemVer from an array of segments.
  #
  # [segments] An array of three integers: <tt>[major, minor, patch]</tt>.
  def initialize(segments, prerelease: nil)
    @segments = segments
    @prerelease = prerelease
  end

  def major = @segments[0] # :nodoc:
  def minor = @segments[1] # :nodoc:
  def patch = @segments[2] # :nodoc:

  # Whether this version promises a stable public API: 1.0 or later, and not a
  # prerelease, which SemVer marks as unstable.
  def stable?
    major >= 1 && @prerelease.nil?
  end

  # Returns the next version after bumping the given segment.
  #
  # Bumping a segment resets all following segments to zero. A prerelease
  # comes before its release, so bumping it to a segment it already leads up
  # to releases it: <tt>1.0.0-rc.1</tt> becomes <tt>1.0.0</tt> on any segment,
  # and <tt>1.2.3-rc.1</tt> becomes <tt>1.2.3</tt> on <tt>:patch</tt>.
  #
  # [segment] One of <tt>:major</tt>, <tt>:minor</tt>, or <tt>:patch</tt>.
  def next(segment)
    index = SEGMENTS.index(segment)
    raise ArgumentError, "Invalid segment: #{segment}" unless index
    return SemVer.new(@segments) if @prerelease && @segments[(index + 1)..].all?(&:zero?)

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
