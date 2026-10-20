# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "cargo_lockfile"
require_relative "manifest"
require_relative "no_crate"
require_relative "../release/native_gem_version"

# A gem's Rust extension. The scaffold names its directory and package after
# the gem with underscores, as Cargo wants; older gems used the gem's name.
class RustCrate < Data.define(:dir) # :nodoc:
  VERSION = /(?<=^version = ")[^"]+(?=")/

  def self.of(gem_name)
    dir = [gem_name.tr("-", "_"), gem_name].map { |name| "ext/#{name}" }.find { |path| File.exist?("#{path}/Cargo.toml") }
    dir ? new(dir:) : NoCrate.new
  end

  def manifests
    [Manifest.new(path: "#{dir}/Cargo.toml", pattern: VERSION)]
  end

  def refresh
    lockfile.refresh
  end

  def lockfile
    CargoLockfile.new(path: "#{dir}/Cargo.lock", dir:, name: package)
  end

  def release_native_gems(version:, sha:)
    NativeGemVersion.new(version:, sha:).release
  end

  private def package
    File.read("#{dir}/Cargo.toml")[/^name = "([^"]+)"/, 1]
  end
end
