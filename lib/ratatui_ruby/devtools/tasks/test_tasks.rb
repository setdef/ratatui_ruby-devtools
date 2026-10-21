# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rake/tasklib"
require "minitest/test_task"

# Minitest task for pure Ruby gems.
#
# Consumer gems need test running. This provides a simple Minitest::TestTask
# that discovers tests in the standard locations. Gems with Rust extensions
# should define their own test task that includes cargo:test.
class TestTasks < Rake::TaskLib # :nodoc:
  def initialize
    super
    define
  end

  private def define
    Minitest::TestTask.create(:test) do |t|
      t.test_globs = ["test/**/*_test.rb", "test/**/test_*.rb"]
    end
  end
end
