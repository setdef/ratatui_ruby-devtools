# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "../bump/sem_ver"

# A compiled native extension binary for a specific Ruby version.
class VersionedBinary < Data.define(:path)
  ##
  # Returns sorted VersionedBinary instances found under +lib_dir+.
  def self.scan(lib_dir, gem_name)
    Dir.glob("#{lib_dir}/*/#{gem_name.tr('-', '_')}.*")
      .reject { |p| p.end_with?(".rb") }
      .map { |p| new(path: p) }
      .sort
  end

  # The full Ruby version string extracted from the directory name.
  def ruby_version
    File.basename(File.dirname(path))
  end

  # The major.minor API version used for Ruby version constraints.
  def api_version
    semver = SemVer.parse(ruby_version)
    "#{semver.major}.#{semver.minor}"
  end

  # Sorts by API version so the binary list is in ascending Ruby order.
  def <=>(other)
    api_version <=> other.api_version
  end
end
