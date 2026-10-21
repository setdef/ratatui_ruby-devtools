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
      Dir.chdir(root) do
        git("init", "-q")
        git("config", "user.name", runner.name)
        git("config", "user.email", runner.email)
        yield new
      end
    end
  end

  def self.git(*args, env: {})
    output, status = Open3.capture2e(env, "git", *args)
    raise "git #{args.join(' ')} failed:\n#{output}" unless status.success?

    output
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
