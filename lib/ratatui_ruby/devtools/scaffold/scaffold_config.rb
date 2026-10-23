# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Configuration for scaffold generation.
#
# Holds all parameters needed to render templates. Auto-discovers author info
# from git config if not provided.
class ScaffoldConfig
  # The gem name to scaffold.
  attr_accessor :gem_name

  # The copyright holder's name.
  attr_accessor :author

  # The copyright holder's email.
  attr_accessor :email

  # The SPDX license identifier.
  attr_accessor :license

  # The output directory path.
  attr_accessor :output_dir

  # Whether this gem includes a Rust native extension.
  attr_accessor :has_rust

  # Creates a new config with defaults from git.
  #
  # Reads author name and email from git config. Sets default license to
  # LGPL-3.0-or-later. Override any accessor after creation.
  def initialize
    @license = "LGPL-3.0-or-later"
    @author = `git config user.name`.strip
    @email = `git config user.email`.strip
    @has_rust = false
  end

  # The gem name with underscores (for module names).
  def module_name
    gem_name.split("-").map { |s| s.split("_").map(&:capitalize).join }.join("::")
  end

  # The gem name with slashes (for require paths).
  def require_path
    gem_name.tr("-", "/")
  end

  # Copyright holder string for SPDX headers.
  def copyright_holder
    "#{author} <#{email}>"
  end

  # Current year for copyright.
  def year
    Time.now.year
  end

  # Ruby versions to test in CI. Each names a minor version, so CI tests its
  # newest patch release.
  def ruby_versions
    %w[3.3 3.4 4.0]
  end
end
