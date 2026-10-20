# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "manifest"
require_relative "rust_crate"

# A gem, found from its files wherever you haven't said otherwise.
class RubyGem < Data.define(:name, :gemspec_file, :version_file) # :nodoc:
  VERSION = /(?<=VERSION = ")[^"]+(?=")/

  def self.found(gemspec_file: nil, name: nil, version_file: nil)
    gemspec_file ||= only_gemspec
    name ||= File.basename(gemspec_file, ".gemspec")
    new(name:, gemspec_file:, version_file: version_file || version_file_of(name))
  end

  def self.only_gemspec
    gemspecs = Dir.glob("*.gemspec")
    raise RatatuiRuby::Devtools::Error, "No *.gemspec found in #{Dir.pwd}" if gemspecs.empty?
    raise RatatuiRuby::Devtools::Error, "Multiple gemspecs found: #{gemspecs.join(', ')}" if gemspecs.size > 1

    gemspecs.first
  end

  # A gem named my_gem-kit keeps its version in lib/my_gem/kit/.
  def self.version_file_of(name)
    path = "lib/#{name.tr('-', '/')}/version.rb"
    return path if File.exist?(path)

    Dir.glob("lib/**/version.rb").first || path
  end

  def crate
    RustCrate.of(name)
  end

  def version
    manifest.version
  end

  def update_version(target)
    [manifest, *crate.manifests].each { |manifest| manifest.write(target) }
    crate.refresh
    refresh_bundler_lockfile
  end

  private def manifest
    Manifest.new(path: version_file, pattern: VERSION)
  end

  private def refresh_bundler_lockfile
    system("bundle install", exception: true)
  end
end
