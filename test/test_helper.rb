# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "date"
require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"

require "ratatui_ruby/devtools"

# A contributor's own git settings, such as commit signing or hooks, would
# change what the fixtures commit and what the tasks read back. Git also
# hands its hooks variables such as GIT_INDEX_FILE and GIT_AUTHOR_NAME, which
# would point a fixture at this repository or at the committer.
ENV.each_key { |name| ENV.delete(name) if name.start_with?("GIT_") }
ENV["GIT_CONFIG_GLOBAL"] = File::NULL
ENV["GIT_CONFIG_NOSYSTEM"] = "1"

# A git repository whose history a test writes, so the license tasks see the
# authors and dates the test chose.
class FixtureRepository
  Person = Data.define(:name, :email)

  KERRICK = Person.new(name: "Kerrick Long", email: "me@kerricklong.com")

  # Creates the repository, makes it the working directory, and removes it
  # afterwards. Runs as +runner+, the person a commit made now would credit.
  def self.open(runner: KERRICK)
    Dir.mktmpdir do |root|
      work = File.join(root, "work")
      Dir.mkdir(work)
      Dir.chdir(work) do
        git("init", "-q")
        git("config", "user.name", runner.name)
        git("config", "user.email", runner.email)
        yield new(root)
      end
    end
  end

  def self.git(*args, env: {})
    output, status = Open3.capture2e(env, "git", *args)
    raise "git #{args.join(' ')} failed:\n#{output}" unless status.success?

    output
  end

  def initialize(root)
    @root = root
  end

  def write(path, text)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, text)
  end

  def read(path)
    File.read(path)
  end

  # Commits everything in the working tree as +author+ on +date+.
  def commit(date:, author: KERRICK)
    time = "#{date}T12:00:00Z"
    env = {
      "GIT_AUTHOR_NAME" => author.name,
      "GIT_AUTHOR_EMAIL" => author.email,
      "GIT_AUTHOR_DATE" => time,
      "GIT_COMMITTER_NAME" => author.name,
      "GIT_COMMITTER_EMAIL" => author.email,
      "GIT_COMMITTER_DATE" => time,
    }
    self.class.git("add", "-A", env:)
    self.class.git("commit", "-q", "--no-verify", "-m", date, env:)
  end

  # Tags the last commit, annotated when there's a +message+, as releases are.
  def tag(name, message: nil)
    self.class.git("tag", *(["-a", "-m", message] if message), name)
  end

  def branch(name)
    self.class.git("branch", name)
  end

  # Creates the branch at HEAD, or names the first commit's branch, and
  # switches to it.
  def start_branch(name)
    self.class.git("checkout", "-q", "-b", name)
  end

  def current_branch
    self.class.git("branch", "--show-current").strip
  end

  # The file as +branch+ has it, whichever branch is checked out.
  def file_on(branch, path)
    self.class.git("show", "#{branch}:#{path}")
  end

  def tags
    self.class.git("tag").split
  end

  # The commit a branch, tag, or HEAD names.
  def commit_of(ref)
    self.class.git("rev-parse", "#{ref}^{commit}").strip
  end

  # A bare repository beside this one, which it pushes to as origin.
  def origin
    @origin ||= FixtureOrigin.create(File.join(@root, "origin.git"))
  end

  def push_branch(name)
    self.class.git("push", "-q", "origin", "HEAD:refs/heads/#{name}")
  end

  def push_tag(name)
    self.class.git("push", "-q", "origin", "refs/tags/#{name}")
  end

  # A gemspec like the ecosystem's: it ships what git tracks outside the
  # directories apps never see.
  def gemspec(license:, extensions: [])
    write("fixture.gemspec", <<~RUBY)
      Gem::Specification.new do |spec|
        spec.name = "fixture"
        spec.version = "0.0.0"
        spec.summary = "Fixture"
        spec.authors = ["Fixture"]
        spec.license = #{license.inspect}
        spec.extensions = #{extensions.inspect}
        spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
          ls.readlines("\\x0", chomp: true).reject { |f| f.start_with?("test/", "examples/", "tasks/", "bin/") }
        end
      end
    RUBY
  end
end

# The remote a FixtureRepository publishes to, as a release pushes to GitHub.
class FixtureOrigin < Data.define(:path)
  def self.create(path)
    FixtureRepository.git("init", "-q", "--bare", path)
    FixtureRepository.git("remote", "add", "origin", path)
    new(path:)
  end

  # The commit origin's branch points to, or nil when origin has no such
  # branch.
  def branch_commit(name)
    commit_of("refs/heads/#{name}")
  end

  # The commit origin's tag releases, or nil when origin has no such tag.
  def tag_commit(name)
    commit_of("refs/tags/#{name}^{}") || commit_of("refs/tags/#{name}")
  end

  private def commit_of(ref)
    FixtureRepository.git("ls-remote", path, ref).split.first
  end
end

class DevtoolsTest < Minitest::Test
  # The licensing of the gem FixtureRepository#gemspec wrote in the current
  # directory.
  def licensing(snippets: [], non_runtime: "AGPL-3.0-or-later")
    Licensing.of(Gem::Specification.load(File.expand_path("fixture.gemspec")), snippets:, non_runtime:)
  end

  def this_year
    Date.today.year
  end
end
