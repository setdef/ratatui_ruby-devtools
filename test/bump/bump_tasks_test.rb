# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "delegate"
require "ratatui_ruby/devtools/tasks/bump_tasks"
require "ratatui_ruby/devtools/tasks/bump/ruby_gem"

class BumpTasksTest < DevtoolsTest
  CHANGELOG = <<~MARKDOWN
    # Changelog

    ## [Unreleased]

    ### Added

    - Something.

    ## [1.0.0] - 2026-01-01

    [Unreleased]: https://example.com/refs/HEAD
    [1.0.0]: https://example.com/refs/tags/v1.0.0
  MARKDOWN

  # Records the versions it's bumped to instead of writing them.
  class RecordingGem
    attr_reader :versions

    def initialize
      @versions = []
    end

    def update_version(target)
      @versions << target.to_s
    end
  end

  def test_defines_a_bump_for_each_segment_and_an_exact_one
    with_rake do
      BumpTasks.new(RecordingGem.new)

      assert_equal %w[bump:exact bump:major bump:minor bump:patch], Rake::Task.tasks.map(&:name).sort
    end
  end

  def test_bumps_the_gem_it_was_given_to_an_exact_version
    with_rake do
      File.write("CHANGELOG.md", CHANGELOG)
      gem = RecordingGem.new
      BumpTasks.new(gem)

      Rake::Task["bump:exact"].invoke("1.1.0")

      assert_equal ["1.1.0"], gem.versions
      assert_includes File.read("CHANGELOG.md"), "## [1.1.0] - "
    end
  end

  def test_patch_finishes_a_trunk_prerelease_by_opening_its_series
    assert_finishes_the_one_zero_beta(:patch)
  end

  def test_minor_finishes_a_trunk_prerelease_by_opening_its_series
    assert_finishes_the_one_zero_beta(:minor)
  end

  def test_major_finishes_a_trunk_prerelease_by_opening_its_series
    assert_finishes_the_one_zero_beta(:major)
  end

  def test_releases_the_next_candidate_on_trunk
    in_bumped_repository("1.2.0-beta.3") do |repository|
      bump(:minor, "rc")

      assert_equal %(VERSION = "1.2.0-rc.1"\n), repository.file_on("trunk", "lib/fixture/version.rb")
      assert_equal %w[trunk], branches
    end
  end

  def test_ships_a_candidate_by_opening_its_series
    in_bumped_repository("1.2.0-rc.1") do |repository|
      bump(:minor)

      assert_equal %(VERSION = "1.2.0"\n), repository.file_on("release/1.2", "lib/fixture/version.rb")
      assert_equal %(VERSION = "1.2.0"\n), repository.file_on("trunk", "lib/fixture/version.rb")
    end
  end

  def test_releases_on_trunk_before_one_zero
    in_bumped_repository("0.2.0") do |repository|
      bump(:minor)

      assert_equal "trunk", repository.current_branch
      assert_equal %(VERSION = "0.3.0"\n), repository.file_on("trunk", "lib/fixture/version.rb")
      assert_equal %w[trunk], branches
    end
  end

  def test_patches_a_series_on_its_release_branch
    in_bumped_repository("1.2.0", branch: "release/1.2") do |repository|
      bump(:patch)

      assert_equal %(VERSION = "1.2.1"\n), repository.file_on("release/1.2", "lib/fixture/version.rb")
      assert_equal %(VERSION = "1.2.0"\n), repository.file_on("trunk", "lib/fixture/version.rb")
    end
  end

  def test_refuses_a_patch_on_trunk
    in_bumped_repository("1.2.0") do
      error = assert_raises(ArgumentError) { bump(:patch) }

      assert_equal "Cannot bump:patch from trunk. Use a release branch.", error.message
    end
  end

  def test_refuses_a_new_series_off_trunk
    in_bumped_repository("1.2.0", branch: "release/1.2") do
      error = assert_raises(ArgumentError) { bump(:minor) }

      assert_equal "Cannot bump:minor from release/1.2. Switch to trunk first.", error.message
    end
  end

  def test_refuses_to_bump_with_uncommitted_changes
    in_bumped_repository("1.2.0") do |repository|
      repository.write("notes.txt", "Unsaved.\n")

      error = assert_raises(ArgumentError) { bump(:minor) }

      assert_equal "Working tree is not clean. Commit or stash changes first.", error.message
    end
  end

  # The fixture gem, writing its version without the bundle install a real
  # bump runs afterwards.
  class BumpedGem < SimpleDelegator
    def update_version(target)
      File.write(version_file, %(VERSION = "#{target}"\n))
    end
  end

  private def assert_finishes_the_one_zero_beta(segment)
    in_bumped_repository("1.0.0-beta.1") do |repository|
      bump(segment)

      assert_equal "release/1.0", repository.current_branch
      assert_equal %(VERSION = "1.0.0"\n), repository.file_on("release/1.0", "lib/fixture/version.rb")
      assert_equal %(VERSION = "1.0.0"\n), repository.file_on("trunk", "lib/fixture/version.rb")
      assert_includes repository.file_on("trunk", "CHANGELOG.md"), "## [1.0.0] - "
    end
  end

  # Commits a gem at +version+ with a changelog that released it, on trunk,
  # then on +branch+ if it's another. Defines the bump tasks for the block.
  private def in_bumped_repository(version, branch: "trunk")
    with_rake_application do
      FixtureRepository.open do |repository|
        repository.start_branch("trunk")
        repository.write("lib/fixture/version.rb", %(VERSION = "#{version}"\n))
        repository.write("CHANGELOG.md", <<~MARKDOWN)
          # Changelog

          ## [Unreleased]

          ### Added

          - Something.

          ## [#{version}] - 2026-01-01

          [Unreleased]: https://example.com/refs/HEAD
          [#{version}]: https://example.com/refs/tags/v#{version}
        MARKDOWN
        repository.commit(date: "2026-01-01")
        repository.start_branch(branch) unless branch == "trunk"
        gem = RubyGem.new(name: "fixture", gemspec_file: "fixture.gemspec", version_file: "lib/fixture/version.rb")
        BumpTasks.new(BumpedGem.new(gem))
        yield repository
      end
    end
  end

  private def bump(segment, label = nil)
    capture_subprocess_io { Rake::Task["bump:#{segment}"].invoke(label) }
  end

  private def branches
    FixtureRepository.git("branch", "--format=%(refname:short)").split
  end

  private def with_rake(&)
    Dir.mktmpdir do |root|
      Dir.chdir(root) { with_rake_application(&) }
    end
  end

  private def with_rake_application
    application = Rake.application
    Rake.application = Rake::Application.new
    yield
  ensure
    Rake.application = application
  end
end
