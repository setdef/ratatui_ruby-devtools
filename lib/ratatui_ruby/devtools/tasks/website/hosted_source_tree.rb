# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "fileutils"

# A version's source, built with the Rakefile, tasks, and bundle of the gem
# building the site.
class HostedSourceTree < Data.define(:path, :gemfile) # :nodoc:
  def self.adopt(path)
    FileUtils.cp("Rakefile", File.join(path, "Rakefile"))
    FileUtils.cp_r("tasks", File.join(path, "tasks")) if Dir.exist?("tasks")
    new(path:, gemfile: File.absolute_path("Gemfile"))
  end

  # Bundler hands its lockfile down with its Gemfile, and resolves either one
  # against the other.
  def run(command, env = {})
    system(env.merge("BUNDLE_GEMFILE" => gemfile, "BUNDLE_LOCKFILE" => "#{gemfile}.lock"), command, chdir: path)
  end
end
