# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "rake"

# REUSE-IgnoreStart
class InstallTest < DevtoolsTest
  def test_the_tasks_work_on_the_gem_and_licensing_you_describe
    in_repository(
      "a.gemspec" => gemspec("a", "Apache-2.0"),
      "b.gemspec" => gemspec("b", "MIT"),
      "lib/b/meta.rb" => %(VERSION = "1.0.0"\n),
      "tasks/a.rb" => "class A; end\n",
      "examples/verify_a/app.rb" => "class App; end\n"
    ) do |repository|
      RatatuiRuby::Devtools.install_gem_tasks!(
        gemspec_file: "b.gemspec",
        version_file: "lib/b/meta.rb",
        non_runtime_license: "LicenseRef-Commercial",
        snippet_paths: %w[examples/verify_]
      )

      refute Object.private_method_defined?(:build_tree)
      assert_equal ["MIT", "LicenseRef-Commercial", "MIT-0"], licenses_after_headers(repository)
      error = assert_raises(SystemExit) do
        assert_output(nil, %r{'lib/b/meta.rb' says v1.0.0, but the latest git tag is v0.9.0}) do
          Rake::Task["release:update_stable"].invoke
        end
      end
      refute error.success?
    end
  end

  def test_the_license_tasks_default_to_the_agpl_and_no_snippets
    in_repository(
      "b.gemspec" => gemspec("b", "MIT"),
      "lib/b/meta.rb" => %(VERSION = "1.0.0"\n),
      "tasks/a.rb" => "class A; end\n",
      "examples/verify_a/app.rb" => "class App; end\n"
    ) do |repository|
      RatatuiRuby::Devtools.install_gem_tasks!

      assert_equal ["MIT", "AGPL-3.0-or-later", "AGPL-3.0-or-later"], licenses_after_headers(repository)
    end
  end

  # Runs the Ruby header task and reads the license each fixture file got.
  private def licenses_after_headers(repository)
    assert_output(/Added header/) { Rake::Task["license:headers:rb"].invoke }

    %w[lib/b/meta.rb tasks/a.rb examples/verify_a/app.rb].map do |path|
      repository.read(path)[/SPDX-License-Identifier: (.*)$/, 1]
    end
  end

  private def gemspec(name, license)
    %(Gem::Specification.new { |spec| spec.name = "#{name}"; spec.license = "#{license}" })
  end

  # Commits +files+ to a repository tagged v0.9.0 and runs the block there,
  # with a Rake application of its own.
  private def in_repository(files)
    application = Rake.application
    Rake.application = Rake::Application.new
    FixtureRepository.open do |repository|
      files.each { |path, text| repository.write(path, text) }
      repository.commit(date: "2024-06-01")
      FixtureRepository.git("tag", "v0.9.0")
      yield repository
    end
  ensure
    Rake.application = application
  end
end
# REUSE-IgnoreEnd
