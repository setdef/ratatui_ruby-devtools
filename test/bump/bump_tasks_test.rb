# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/bump_tasks"

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

  private def with_rake
    application = Rake.application
    Dir.mktmpdir do |root|
      Dir.chdir(root) do
        Rake.application = Rake::Application.new
        yield
      end
    end
  ensure
    Rake.application = application
  end
end
