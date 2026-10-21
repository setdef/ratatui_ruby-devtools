# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/license/changed_files"

# REUSE-IgnoreStart
class ChangedFilesTest < DevtoolsTest
  def test_says_when_nothing_changed
    FixtureRepository.open do |repository|
      repository.gemspec(license: "LGPL-3.0-or-later")
      repository.commit(date: "2024-06-01")

      assert_equal ["No changed Markdown, Ruby, RBS, or Rust files to process"], license(repository)
    end
  end

  def test_licenses_modified_staged_and_untracked_files_by_language
    FixtureRepository.open do |repository|
      repository.gemspec(license: "LGPL-3.0-or-later", extensions: ["ext/fixture/extconf.rb"])
      repository.write("lib/kept.rb", "class Kept; end\n")
      repository.write("lib/modified.rb", "class Modified; end\n")
      repository.write("lib/staged.rb", "class Staged; end\n")
      repository.write("sig/fixture/modified.rbs", "class Modified\nend\n")
      repository.write("ext/fixture/src/modified.rs", "fn modified() {}\n")
      repository.write("doc/guide.md", "# Guide\n\nText.\n")
      repository.commit(date: "2024-06-01")
      repository.write("lib/modified.rb", "class Modified; def x; end; end\n")
      repository.write("lib/staged.rb", "class Staged; def y; end; end\n")
      FixtureRepository.git("add", "lib/staged.rb")
      repository.write("lib/untracked.rb", "class Untracked; end\n")
      repository.write("sig/fixture/modified.rbs", "class Modified\n  def x: () -> void\nend\n")
      repository.write("ext/fixture/src/modified.rs", "fn modified() { 1; }\n")
      repository.write("doc/guide.md", "# Guide\n\nMore text.\n")

      assert_equal [
        "Processing 1 changed Markdown file(s)...",
        "Added header: doc/guide.md",
        "Processing 3 changed Ruby file(s)...",
        "Added header: lib/modified.rb",
        "Added header: lib/staged.rb",
        "Added header: lib/untracked.rb",
        "Processing 1 changed RBS file(s)...",
        "Added header: sig/fixture/modified.rbs",
        "Processing 1 changed Rust file(s)...",
        "Added header: ext/fixture/src/modified.rs",
      ], license(repository)
      assert_equal "class Kept; end\n", repository.read("lib/kept.rb")
      assert_includes repository.read("lib/untracked.rb"), "SPDX-FileCopyrightText: #{this_year} Kerrick Long"
    end
  end

  def test_wraps_the_examples_in_changed_files
    FixtureRepository.open do |repository|
      repository.gemspec(license: "LGPL-3.0-or-later")
      repository.commit(date: "2024-06-01")
      repository.write("lib/thing.rb", "# Makes things.\n#\n#   Thing.new\nclass Thing; end\n")
      repository.write("doc/guide.md", "# Guide\n\n```ruby\nputs 1\n```\n")

      messages = license(repository)

      assert_includes messages, "Updated: lib/thing.rb (1 code block(s))"
      assert_includes messages, "Updated: doc/guide.md (1 code block(s))"
    end
  end

  private def license(repository)
    ChangedFiles.new(Repository.new, licensing).license
  end
end
# REUSE-IgnoreEnd
