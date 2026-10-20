# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
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
      release = Rake::Task.define_task(:release)
      ReleaseTasks.new(gem)

      assert_equal 1, release.actions.size
    end
  end

  def test_refuses_to_move_stable_when_the_version_file_and_tag_disagree
    with_rake do
      FixtureRepository.open do |repository|
        repository.write("lib/fixture/meta.rb", %(VERSION = "1.1.0"\n))
        repository.commit(date: "2026-01-01")
        FixtureRepository.git("tag", "v1.0.0")
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
