# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/license_tasks"

# REUSE-IgnoreStart
class LicenseTasksTest < DevtoolsTest
  LICENSING = Licensing.new(snippets: [], linked: ["lib/"], runtime: "MIT", non_runtime: "Apache-2.0")

  def test_headers_take_the_license_the_licensing_gives_them
    in_repository("lib/a.rb" => "class A; end\n", "tasks/b.rb" => "class B; end\n") do |repository|
      assert_output(%r{Added header: lib/a.rb}) { Rake::Task["license:headers:rb"].invoke }

      assert_includes repository.read("lib/a.rb"), "# SPDX-License-Identifier: MIT\n"
      assert_includes repository.read("tasks/b.rb"), "# SPDX-License-Identifier: Apache-2.0\n"
    end
  end

  def test_changed_files_take_the_license_the_licensing_gives_them
    in_repository("lib/a.rb" => "class A; end\n") do |repository|
      repository.write("lib/c.rb", "class C; end\n")

      assert_output(/Processing 1 changed Ruby file/) { Rake::Task["license:new"].invoke }

      assert_includes repository.read("lib/c.rb"), "# SPDX-License-Identifier: MIT\n"
    end
  end

  # Commits +files+ to a repository with no gemspec, where only the
  # licensing the tasks were built with can say how to license them.
  private def in_repository(files)
    application = Rake.application
    Rake.application = Rake::Application.new
    FixtureRepository.open do |repository|
      files.each { |path, text| repository.write(path, text) }
      repository.commit(date: "2024-06-01")
      LicenseTasks.new(LICENSING)
      yield repository
    end
  ensure
    Rake.application = application
  end
end
# REUSE-IgnoreEnd
