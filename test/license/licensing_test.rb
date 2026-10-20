# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/license/licensing"
require "ratatui_ruby/devtools/tasks/license/rbs_header_syntax"
require "ratatui_ruby/devtools/tasks/license/ruby_header_syntax"
require "ratatui_ruby/devtools/tasks/license/rust_header_syntax"

class LicensingTest < DevtoolsTest
  def test_code_apps_link_takes_the_gemspec_license
    licensing = fixture_licensing(license: "LGPL-3.0-or-later", extensions: ["ext/fixture/extconf.rb"])

    assert_equal "LGPL-3.0-or-later", licensing.license_for("lib/fixture.rb")
    assert_equal "LGPL-3.0-or-later", licensing.license_for("ext/fixture/src/lib.rs")
  end

  def test_code_apps_dont_link_takes_the_agpl
    licensing = fixture_licensing(license: "LGPL-3.0-or-later", extensions: ["ext/fixture/extconf.rb"])

    %w[test/a_test.rb sig/fixture/a.rbs exe/fixture tasks/a.rake bin/setup ext/other.rs examples/app_a/app.rb]
      .each { |path| assert_equal "AGPL-3.0-or-later", licensing.license_for(path), path }
  end

  def test_a_file_not_yet_in_git_takes_its_directorys_license
    licensing = fixture_licensing(license: "LGPL-3.0-or-later")

    assert_equal "LGPL-3.0-or-later", licensing.license_for("lib/new_file.rb")
  end

  def test_an_agpl_gem_links_under_the_agpl
    licensing = fixture_licensing(license: "AGPL-3.0-or-later")

    assert_equal "AGPL-3.0-or-later", licensing.license_for("lib/fixture.rb")
  end

  def test_examples_are_mit_0_only_under_snippet_paths
    RatatuiRuby::Devtools.snippet_paths = %w[examples/widget_ sig/examples/widget_]
    licensing = fixture_licensing(license: "LGPL-3.0-or-later")

    assert_equal "MIT-0", licensing.license_for("examples/widget_a/app.rb")
    assert_equal "MIT-0", licensing.license_for("sig/examples/widget_a/app.rbs")
    assert_equal "AGPL-3.0-or-later", licensing.license_for("examples/verify_a/app.rb")
  end

  def test_without_snippet_paths_no_example_is_mit_0
    licensing = fixture_licensing(license: "LGPL-3.0-or-later")

    assert_equal "AGPL-3.0-or-later", licensing.license_for("examples/widget_a/app.rb")
  end

  def test_a_gem_can_license_what_apps_dont_link_differently
    RatatuiRuby::Devtools.non_runtime_license = "LicenseRef-Commercial"
    licensing = fixture_licensing(license: "LGPL-3.0-or-later")

    assert_equal "LicenseRef-Commercial", licensing.license_for("test/a_test.rb")
    assert_equal "LGPL-3.0-or-later", licensing.license_for("lib/fixture.rb")
  end

  def test_reads_what_apps_link_and_its_license_from_a_spec
    spec = Gem::Specification.new do |gem|
      gem.licenses = %w[MIT Apache-2.0]
      gem.require_paths = %w[lib]
      gem.extensions = %w[ext/fixture/extconf.rb]
    end
    licensing = Licensing.of(spec, snippets: %w[examples/widget_], non_runtime: "AGPL-3.0-or-later")

    assert_equal "MIT OR Apache-2.0", licensing.license_for("lib/fixture.rb")
    assert_equal "MIT OR Apache-2.0", licensing.license_for("ext/fixture/src/lib.rs")
    assert_equal "MIT-0", licensing.license_for("examples/widget_a/app.rb")
    assert_equal "AGPL-3.0-or-later", licensing.license_for("tasks/a.rake")
  end

  def test_header_syntaxes_license_by_the_licensing_they_are_given
    licensing = Licensing.new(snippets: [], linked: ["lib/"], runtime: "MIT", non_runtime: "Apache-2.0")

    Dir.mktmpdir do |root|
      Dir.chdir(root) do
        assert_equal "MIT", RubyHeaderSyntax.new(licensing).license_for("lib/a.rb")
        assert_equal "Apache-2.0", RbsHeaderSyntax.new(licensing).license_for("sig/a.rbs")
        assert_equal "Apache-2.0", RustHeaderSyntax.new(licensing).license_for("tasks/a.rs")
      end
    end
  end

  private def fixture_licensing(license:, extensions: [])
    licensing = nil
    FixtureRepository.open do |repository|
      repository.write("lib/fixture.rb", "")
      repository.gemspec(license:, extensions:)
      repository.commit(date: "2026-01-01")
      licensing = Licensing.current
    end
    licensing
  end
end
