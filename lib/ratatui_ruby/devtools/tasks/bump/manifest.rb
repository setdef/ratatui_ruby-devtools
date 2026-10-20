# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "sem_ver"

# Represents a file that contains a version number.
#
# Gems have version numbers in multiple places: version.rb, Cargo.toml, etc.
# Finding and updating them by hand risks inconsistency. One file says 1.2.3,
# another says 1.2.2.
#
# This class wraps a file path with a regex pattern. It reads the current
# version and writes new versions. Use lookaround patterns to match precisely.
#
# [path] The file path.
# [pattern] A regex with lookarounds to match the version string.
# [primary] Whether this is the primary source of truth.
#
# === Example
#
#   manifest = Manifest.new(
#     path: "lib/my_gem/version.rb",
#     pattern: /(?<=VERSION = ")[^"]+(?=")/,
#     primary: true
#   )
#   manifest.version.to_s  # => "1.2.3"
#
class Manifest < Data.define(:path, :pattern, :primary)
  # Creates a new Manifest.
  #
  # [path] The file path.
  # [pattern] A regex with lookarounds to match the version string.
  # [primary] Whether this is the primary source of truth.
  def initialize(path:, pattern:, primary: false)
    super
  end

  # Reads the file content.
  def read
    File.read(path)
  end

  # Returns the current version from this manifest.
  def version
    content = read
    match = content.match(pattern)
    raise "Version missing in manifest #{path}" unless match

    SemVer.parse(match[0])
  end

  # Writes a new version to this manifest.
  #
  # [version] The SemVer to write.
  def write(version)
    return unless File.exist?(path)

    new_content = read.gsub(pattern, version.to_s)
    File.write(path, new_content)
  end
end
