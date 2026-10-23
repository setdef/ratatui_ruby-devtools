# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "lib/ratatui_ruby/devtools/version"

Gem::Specification.new do |spec|
  spec.name = "ratatui_ruby-devtools"
  spec.version = RatatuiRuby::Devtools::VERSION
  spec.authors = ["Kerrick Long"]
  spec.email = ["me@kerricklong.com"]

  spec.summary = "Development tooling for the RatatuiRuby ecosystem."
  spec.description = "Shared Rake tasks, linters, and build tooling for RatatuiRuby ecosystem gems."
  spec.homepage = "https://github.com/setdef/ratatui_ruby-devtools"
  spec.license = "AGPL-3.0-or-later"
  spec.required_ruby_version = ">= 3.3.11"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "https://github.com/setdef/ratatui_ruby-devtools/issues"
  spec.metadata["changelog_uri"] = "https://github.com/setdef/ratatui_ruby-devtools/blob/stable/CHANGELOG.md"
  spec.metadata["source_code_uri"] = "https://github.com/setdef/ratatui_ruby-devtools"
  spec.metadata["wiki_uri"] = "https://man.sr.ht/~kerrick/ratatui_ruby/"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[test/ spec/ features/ .git .github Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies (tools this gem provides)
  spec.add_dependency "inch", ">= 0.8"
  spec.add_dependency "minitest", ">= 5.16", "< 7"
  spec.add_dependency "nokogiri", ">= 1.16"
  spec.add_dependency "ostruct", ">= 0.6"
  spec.add_dependency "rake", ">= 13.0"
  spec.add_dependency "rdoc", ">= 8.1"
  spec.add_dependency "rubocop", ">= 1.0"
  spec.add_dependency "rubycritic", ">= 4.0"
end
