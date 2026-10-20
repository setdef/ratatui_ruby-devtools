# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "rake"

class InstallTest < DevtoolsTest
  # The task files define methods as they load, so loading them twice in one
  # process would redefine those methods.
  def test_installs_the_tasks_with_the_settings_you_pass_and_keeps_the_rest
    in_gem("a.gemspec", "b.gemspec") do
      RatatuiRuby::Devtools.snippet_paths = %w[examples/verify_]
      RatatuiRuby::Devtools.install_gem_tasks!(
        gemspec_file: "b.gemspec",
        version_file: "lib/b/meta.rb",
        non_runtime_license: "LicenseRef-Commercial"
      )

      assert Rake::Task.task_defined?("bump:patch")
      assert_equal ["b", "b.gemspec", "lib/b/meta.rb"],
        [RatatuiRuby::Devtools.gem_name, RatatuiRuby::Devtools.gemspec_file, RatatuiRuby::Devtools.version_file]
      assert_equal "LicenseRef-Commercial", RatatuiRuby::Devtools.non_runtime_license
      assert_equal %w[examples/verify_], RatatuiRuby::Devtools.snippet_paths
    end
  end

  def teardown
    RatatuiRuby::Devtools.version_file = nil
    super
  end

  # Runs the block in a gem holding empty +files+, with a Rake application
  # of its own.
  private def in_gem(*files)
    application = Rake.application
    Dir.mktmpdir do |root|
      Dir.chdir(root) do
        files.each { |file| File.write(file, "") }
        Rake.application = Rake::Application.new
        yield
      end
    end
  ensure
    Rake.application = application
  end
end
