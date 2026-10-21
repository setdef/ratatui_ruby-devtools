# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "rake"

class InstallTest < DevtoolsTest
  def test_installs_the_tasks_with_the_settings_you_pass_and_keeps_the_rest
    in_gem("a.gemspec", "b.gemspec") do
      RatatuiRuby::Devtools.snippet_paths = %w[examples/verify_]
      RatatuiRuby::Devtools.install_gem_tasks!(
        gemspec_file: "b.gemspec",
        version_file: "lib/b/meta.rb",
        non_runtime_license: "LicenseRef-Commercial"
      )

      assert Rake::Task.task_defined?("bump:patch")
      refute Object.private_method_defined?(:build_tree)
      refute Object.const_defined?(:CapturingToHtml)
      assert_equal ["b", "b.gemspec", "lib/b/meta.rb"],
        [RatatuiRuby::Devtools.gem_name, RatatuiRuby::Devtools.gemspec_file, RatatuiRuby::Devtools.version_file]
      assert_equal "LicenseRef-Commercial", RatatuiRuby::Devtools.non_runtime_license
      assert_equal %w[examples/verify_], RatatuiRuby::Devtools.snippet_paths
    end
  end

  # REUSE-IgnoreStart
  def test_the_license_tasks_license_by_your_settings_and_their_defaults
    with_rake do
      FixtureRepository.open do |repository|
        repository.gemspec(license: "MIT")
        repository.write("lib/fixture.rb", "class Fixture; end\n")
        repository.write("tasks/a.rb", "class A; end\n")
        repository.write("examples/verify_a/app.rb", "class App; end\n")
        repository.commit(date: "2024-06-01")
        RatatuiRuby::Devtools.snippet_paths = %w[examples/verify_]
        RatatuiRuby::Devtools.install_gem_tasks!

        assert_output(/Added header/) { Rake::Task["license:headers:rb"].invoke }

        assert_equal ["MIT", "AGPL-3.0-or-later", "MIT-0"],
          %w[lib/fixture.rb tasks/a.rb examples/verify_a/app.rb].map { |path| repository.read(path)[/SPDX-License-Identifier: (.*)$/, 1] }
      end
    end
  end
  # REUSE-IgnoreEnd

  def teardown
    RatatuiRuby::Devtools.version_file = nil
    super
  end

  # Runs the block in a gem holding the gemspecs +files+, with a Rake application
  # of its own.
  private def in_gem(*files)
    application = Rake.application
    Dir.mktmpdir do |root|
      Dir.chdir(root) do
        files.each { |file| File.write(file, %(Gem::Specification.new { |spec| spec.name = "#{File.basename(file, '.gemspec')}" })) }
        Rake.application = Rake::Application.new
        yield
      end
    end
  ensure
    Rake.application = application
  end

  private def with_rake
    application = Rake.application
    Rake.application = Rake::Application.new
    yield
  ensure
    Rake.application = application
  end
end
