# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rubygems"

require_relative "bump/sem_ver"
require_relative "bump/manifest"
require_relative "bump/ruby_gem"
require_relative "bump/rust_crate"
require_relative "bump/release_from_trunk"
require_relative "bump/patch_release"
require_relative "bump/unbranched_release"

namespace :bump do
  # Auto-discover gem configuration
  def devtools_gem
    @devtools_gem ||= begin
      crate = RustCrate.of(RatatuiRuby::Devtools.gem_name)
      version = Manifest.new(path: RatatuiRuby::Devtools.version_file, pattern: /(?<=VERSION = ")[^"]+(?=")/, primary: true)

      RubyGem.new(manifests: [version, *crate.manifests], crate:)
    end
  end

  desc "Bump major version"
  task :major do
    BumpWorkflow.for(devtools_gem, :major).call(:major)
  end

  desc "Bump minor version"
  task :minor do
    BumpWorkflow.for(devtools_gem, :minor).call(:minor)
  end

  desc "Bump patch version"
  task :patch do
    BumpWorkflow.for(devtools_gem, :patch).call(:patch)
  end

  desc "Set exact version (e.g. rake bump:exact[0.1.0])"
  task :exact, [:version] do |_, args|
    target = SemVer.parse(args[:version])
    changelog = Changelog.new
    changelog.release(target)
    devtools_gem.update_version(target)
  end
end
