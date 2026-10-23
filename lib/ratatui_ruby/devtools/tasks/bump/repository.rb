# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "open3"
require "rake/file_utils_ext"
require "tmpdir"

class Repository # :nodoc:
  # Releasing shows each git command it runs, as rake tasks do.
  include Rake::FileUtilsExt

  TRUNK = "trunk"
  STABLE = "stable"

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
    git("branch", "--show-current").strip
  end

  def tracked_files(pattern)
    git("ls-files", pattern).split("\n")
  end

  # The tracked files a syntax covers, under the given paths, or everywhere
  # it looks by default. A path that isn't a directory is taken as it is, if
  # it's written in the syntax. In a git pathspec * crosses directories, so
  # dir/*.rb reaches every depth, while dir/**/*.rb would skip the files
  # directly inside dir.
  def tracked_files_for(paths, syntax)
    return syntax.tracked_patterns.flat_map { |pattern| tracked_files(pattern) }.uniq if paths.empty?

    paths.flat_map do |path|
      if File.directory?(path)
        syntax.extensions.flat_map { |extension| tracked_files("#{path}/*.#{extension}") }
      elsif syntax.extensions.include?(File.extname(path).delete_prefix("."))
        [path]
      else
        []
      end
    end
  end

  # Added, copied, modified, or renamed since HEAD, staged or not, plus new
  # untracked files. The staged diff also covers a repository with no commits.
  def changed_files
    [
      git("diff", "--name-only", "--diff-filter=ACMR", "HEAD"),
      git("diff", "--name-only", "--cached", "--diff-filter=ACMR"),
      git("ls-files", "--others", "--exclude-standard"),
    ].flat_map { |output| output.split("\n") }.uniq
  end

  def latest_tag
    git("describe", "--tags", "--abbrev=0").strip
  end

  # An annotated tag is an object of its own, and a branch can only point at
  # a commit.
  def released_commit(tag)
    git("rev-parse", "#{tag}^{}").strip
  end

  # The file as the stable branch has it, or nil when there's no such branch
  # or file.
  def stable_file(path)
    text = git("show", "#{STABLE}:#{path}")
    text unless text.empty?
  end

  # Stable is reset to each release rather than fast-forwarded, so origin's
  # copy is overwritten. Git can't tell that a bare name is meant as a branch
  # when origin has none yet, as after the scaffold, so the push names it in
  # full.
  def move_stable(commit)
    sh "git", "branch", "-f", STABLE, commit
    sh "git", "push", "--force", "origin", "#{commit}:refs/heads/#{STABLE}"
  end

  # Deletes the tag here and on origin.
  def delete_tag(name)
    sh "git", "tag", "-d", name
    sh "git", "push", "origin", ":refs/tags/#{name}"
  end

  # Tags HEAD here and on origin.
  def tag_head(name)
    sh "git", "tag", name, "HEAD"
    sh "git", "push", "origin", name
  end

  def create_branch(name)
    system("git", "checkout", "-b", name, exception: true)
  end

  def checkout(name)
    system("git", "checkout", name, exception: true)
  end

  def assert_pristine!
    return if git("status", "--porcelain").strip.empty?

    raise ArgumentError, "Working tree is not clean. Commit or stash changes first."
  end

  def commit_all(message)
    msg_file = File.join(Dir.tmpdir, "ratatui_ruby_commit_msg_#{$$}.txt")
    system("git", "add", "-A", exception: true)
    File.write(msg_file, message)
    system("git", "commit", "-F", msg_file, exception: true)
  ensure
    File.delete(msg_file) if msg_file && File.exist?(msg_file)
  end

  # Runs git directly rather than through a shell, whose quoting and
  # redirection differ on Windows, and keeps its complaints out of the
  # output it answers with.
  private def git(*)
    Open3.capture2("git", *, err: File::NULL).first
  end
end
