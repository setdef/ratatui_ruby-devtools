# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "open3"
require "shellwords"
require "tmpdir"

class Repository # :nodoc:
  TRUNK = "trunk"

  class Author < Data.define(:name, :email) # :nodoc:
    def to_s
      "#{name} <#{email}>"
    end
  end

  # The identity your next commit would carry, from git config or the
  # GIT_AUTHOR_* variables. Without useConfigOnly, git would guess an email
  # from the hostname, and that guess would end up in copyright headers.
  def author
    ident, status = Open3.capture2("git", "-c", "user.useConfigOnly=true", "var", "GIT_AUTHOR_IDENT", err: File::NULL)
    name, email = ident.match(/\A(.+) <(.*)> \d+ [+-]\d{4}\n?\z/)&.captures
    return Author.new(name:, email:) if status.success? && name && email

    raise ArgumentError, "Git doesn't know who you are. Run: git config --global user.name \"Your Name\" " \
      "and git config --global user.email you@example.com"
  end

  def on_trunk? = current_branch == TRUNK

  def current_branch
    `git branch --show-current`.strip
  end

  def tracked_files(pattern)
    `git ls-files '#{pattern}' 2>/dev/null`.split("\n")
  end

  # The tracked files a syntax covers, under the given paths, or everywhere
  # it looks by default. A path that isn't a directory is taken as it is.
  # In a git pathspec * crosses directories, so dir/*.rb reaches every depth,
  # while dir/**/*.rb would skip the files directly inside dir.
  def tracked_files_for(paths, syntax)
    return syntax.tracked_patterns.flat_map { |pattern| tracked_files(pattern) }.uniq if paths.empty?

    paths.flat_map do |path|
      next path unless File.directory?(path)

      syntax.extensions.flat_map { |extension| tracked_files("#{path}/*.#{extension}") }
    end
  end

  # Added, copied, modified, or renamed since HEAD, staged or not, plus new
  # untracked files. The staged diff also covers a repository with no commits.
  def changed_files
    [
      `git diff --name-only --diff-filter=ACMR HEAD 2>/dev/null`,
      `git diff --name-only --cached --diff-filter=ACMR 2>/dev/null`,
      `git ls-files --others --exclude-standard`,
    ].flat_map { |output| output.split("\n") }.uniq
  end

  def create_branch(name)
    system("git checkout -b #{name}", exception: true)
  end

  def checkout(name)
    system("git checkout #{name}", exception: true)
  end

  def assert_can_bump!(segment)
    assert_pristine!

    if on_trunk? && segment == :patch
      raise ArgumentError, "Cannot bump:patch from trunk. Use a release branch."
    end

    if !on_trunk? && [:minor, :major].include?(segment)
      raise ArgumentError, "Cannot bump:#{segment} from #{current_branch}. Switch to trunk first."
    end
  end

  def assert_pristine!
    return if `git status --porcelain`.strip.empty?

    raise ArgumentError, "Working tree is not clean. Commit or stash changes first."
  end

  def commit_all(message)
    msg_file = File.join(Dir.tmpdir, "ratatui_ruby_commit_msg_#{$$}.txt")
    system("git add -A", exception: true)
    File.write(msg_file, message)
    system("git commit -F #{msg_file.shellescape}", exception: true)
  ensure
    File.delete(msg_file) if msg_file && File.exist?(msg_file)
  end
end
