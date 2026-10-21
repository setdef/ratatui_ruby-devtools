# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/reuse_tasks"

# REUSE-IgnoreStart
class ReuseTasksTest < DevtoolsTest
  def test_fixes_headers_with_the_license_the_licensing_gives_them
    application = Rake.application
    Rake.application = Rake::Application.new
    FixtureRepository.open do |repository|
      repository.write("lib/a.rb", "class A; end\n")
      repository.commit(date: "2024-06-01")
      ReuseTasks.new(Licensing.new(snippets: [], linked: ["lib/"], runtime: "MIT", non_runtime: "Apache-2.0"))

      assert_output(%r{Added header: lib/a.rb}) { Rake::Task["reuse:fix"].invoke }

      assert_includes repository.read("lib/a.rb"), "# SPDX-License-Identifier: MIT\n"
    end
  ensure
    Rake.application = application
  end
end
# REUSE-IgnoreEnd
