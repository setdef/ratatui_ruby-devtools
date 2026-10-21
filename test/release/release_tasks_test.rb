# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "delegate"
require "ratatui_ruby/devtools/tasks/release_tasks"

class ReleaseTasksTest < DevtoolsTest
  def test_defines_the_release_tasks
    with_rake do
      ReleaseTasks.new(gem)

      assert_equal %w[release:platform_gem release:update_stable], Rake::Task.tasks.map(&:name).sort
    end
  end

  def test_adds_to_bundlers_release_task_when_there_is_one
    with_rake do
      release = Rake::Task.define_task(release: :build)
      ReleaseTasks.new(gem)

      assert_equal 1, release.actions.size
      assert_equal %w[release:check_version build], release.prerequisites
    end
  end

  def test_refuses_to_move_stable_when_the_version_file_and_tag_disagree
    with_rake do
      FixtureRepository.open do |repository|
        repository.write("lib/fixture/meta.rb", %(VERSION = "1.1.0"\n))
        repository.commit(date: "2026-01-01")
        repository.tag("v1.0.0")
        ReleaseTasks.new(gem(version_file: "lib/fixture/meta.rb"))

        error = assert_raises(SystemExit) do
          assert_output(nil, %r{'lib/fixture/meta.rb' says v1.1.0, but the latest git tag is v1.0.0}) do
            Rake::Task["release:update_stable"].invoke
          end
        end
        refute error.success?
      end
    end
  end

  def test_moves_stable_to_the_released_commit_here_and_on_origin
    in_released_repository("1.1.0", stable: "1.0.0") do |repository|
      released = repository.commit_of("v1.1.0")

      capture_subprocess_io { Rake::Task["release:update_stable"].invoke }

      assert_equal released, repository.commit_of("stable")
      assert_equal released, repository.origin.branch_commit("stable")
    end
  end

  def test_moves_stable_when_only_origin_has_it
    in_released_repository("1.1.0") do |repository|
      out, = capture_subprocess_io { Rake::Task["release:update_stable"].invoke }

      assert_includes out, "Updating stable branch to point to v1.1.0..."
      assert_equal repository.commit_of("v1.1.0"), repository.origin.branch_commit("stable")
    end
  end

  def test_leaves_stable_alone_when_it_is_not_older
    in_released_repository("1.1.0", stable: "1.1.0") do |repository|
      stable = repository.commit_of("stable")

      out, = capture_subprocess_io { Rake::Task["release:update_stable"].invoke }

      assert_equal "Skipping stable update: 1.1.0 is not newer than current stable 1.1.0\n", out
      assert_equal stable, repository.commit_of("stable")
      assert_equal stable, repository.origin.branch_commit("stable")
    end
  end

  def test_moves_stable_past_a_version_from_before_semver
    in_released_repository("0.1.0", stable: "0.0.1.pre.1") do |repository|
      capture_subprocess_io { Rake::Task["release:update_stable"].invoke }

      assert_equal repository.commit_of("v0.1.0"), repository.origin.branch_commit("stable")
    end
  end

  def test_refuses_a_version_that_is_not_semver_before_bundler_publishes
    in_released_repository("1.0.0.beta.1") do |repository|
      stable = repository.origin.branch_commit("stable")

      error = assert_raises(ArgumentError) { Rake::Task["release"].invoke }

      assert_equal "1.0.0.beta.1 is not SemVer. Put the prerelease after a hyphen, like 1.0.0-beta.1.", error.message
      refute Rake::Task["build"].already_invoked
      assert_equal %w[v1.0.0.beta.1], repository.tags
      assert_equal stable, repository.origin.branch_commit("stable")
    end
  end

  def test_refuses_a_version_written_short_before_bundler_publishes
    in_released_repository("1.2") do
      error = assert_raises(ArgumentError) { Rake::Task["release"].invoke }

      assert_equal "lib/fixture/version.rb says 1.2. Write it as 1.2.0 before releasing.", error.message
      refute Rake::Task["build"].already_invoked
    end
  end

  def test_the_release_hook_releases_native_gems_from_the_tagged_commit_and_moves_stable
    crate = RecordingCrate.new
    in_released_repository("1.1.0", crate:) do |repository|
      capture_subprocess_io { Rake::Task["release"].invoke }

      released = repository.commit_of("v1.1.0")
      assert_equal [{ version: "1.1.0", sha: released }], crate.releases
      assert_equal released, repository.origin.branch_commit("stable")
      assert_equal %w[v1.1.0], repository.tags
    end
  end

  def test_the_release_hook_replaces_bundlers_prerelease_tag_with_the_semver_tag
    in_released_repository("1.0.0-beta.1", tag: "v1.0.0.pre.beta.1") do |repository|
      released = repository.commit_of("HEAD")

      out, = capture_subprocess_io { Rake::Task["release"].invoke }

      assert_includes out, "Replacing normalized tag v1.0.0.pre.beta.1 with semver tag v1.0.0-beta.1..."
      assert_equal %w[v1.0.0-beta.1], repository.tags
      assert_nil repository.origin.tag_commit("v1.0.0.pre.beta.1")
      assert_equal released, repository.origin.tag_commit("v1.0.0-beta.1")
      assert_equal released, repository.origin.branch_commit("stable")
    end
  end

  # Records the native gems it's asked to release.
  class RecordingCrate
    attr_reader :releases

    def initialize
      @releases = []
    end

    def release_native_gems(version:, sha:)
      @releases << { version:, sha: }
    end
  end

  # The fixture gem, with a crate the test chooses.
  class ReleasedGem < SimpleDelegator
    attr_reader :crate

    def initialize(gem, crate)
      super(gem)
      @crate = crate
    end
  end

  # Commits the previous release, which origin's stable branch holds, and
  # makes it the local stable branch too if +stable+ names its version. Then
  # commits +version+ and tags it as +tag+ the way Bundler's release does,
  # pushed to origin. Defines Bundler's release task, which builds and
  # publishes in its prerequisites, and the release tasks for the block.
  private def in_released_repository(version, stable: nil, tag: "v#{version}", crate: NoCrate.new)
    with_rake do
      FixtureRepository.open do |repository|
        repository.origin
        repository.write("lib/fixture/version.rb", %(VERSION = "#{stable || '0.9.0'}"\n))
        repository.commit(date: "2026-01-01")
        repository.push_branch("stable")
        repository.branch("stable") if stable
        repository.write("lib/fixture/version.rb", %(VERSION = "#{version}"\n))
        repository.write("CHANGELOG.md", "Released.\n")
        repository.commit(date: "2026-02-01")
        repository.tag(tag, message: "Version #{version}")
        repository.push_branch("trunk")
        repository.push_tag(tag)
        Rake::Task.define_task(:build)
        Rake::Task.define_task(release: :build)
        ReleaseTasks.new(ReleasedGem.new(gem, crate))
        yield repository
      end
    end
  end

  private def gem(version_file: "lib/fixture/version.rb")
    RubyGem.new(name: "fixture", gemspec_file: "fixture.gemspec", version_file:)
  end

  private def with_rake
    application = Rake.application
    Rake.application = Rake::Application.new
    yield
  ensure
    Rake.application = application
  end
end
