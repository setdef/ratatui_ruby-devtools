# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/bump/repository"
require "ratatui_ruby/devtools/tasks/license/reuse_tool"
require "ratatui_ruby/devtools/tasks/license/unlicensed_files"

# REUSE-IgnoreStart
class ReuseTest < DevtoolsTest
  KERRICK = "Kerrick Long <me@kerricklong.com>"
  # For a gem outside any repository, whose files the overrides license.
  ANY_LICENSING = Licensing.new(snippets: [], linked: ["lib/"], runtime: "MIT", non_runtime: "MIT")

  # Reports the paths it's given and records what it's asked to annotate.
  class RecordingTool
    attr_reader :annotated, :unlicensed_paths

    def initialize(unlicensed_paths)
      @unlicensed_paths = unlicensed_paths
      @annotated = []
    end

    def annotate(path, license:, copyright:)
      @annotated << [path, license, copyright]
      ["Successfully changed header of #{path}"]
    end
  end

  # A repository that can't say who you are, as in CI.
  class AnonymousRepository
    def author
      raise ArgumentError, "Git doesn't know who you are."
    end
  end

  def test_says_when_every_file_has_a_header
    messages = UnlicensedFiles.new(RecordingTool.new([]), AnonymousRepository.new, {}, ANY_LICENSING).license

    assert_equal ["All files have REUSE headers!"], messages
  end

  def test_gives_files_the_license_tasks_cover_their_headers
    tool = RecordingTool.new(%w[lib/a.rb sig/fixture/a.rbs doc/guide.md])
    in_gem("lib/a.rb" => "class A; end\n", "sig/fixture/a.rbs" => "class A\nend\n", "doc/guide.md" => "# Guide\n") do |repository|
      messages = UnlicensedFiles.new(tool, Repository.new, {}, licensing).license

      assert_equal ["  Added header: lib/a.rb", "  Added header: sig/fixture/a.rbs", "  Added header: doc/guide.md"], messages
      assert_empty tool.annotated
      assert_includes repository.read("lib/a.rb"), "#--\n# SPDX-FileCopyrightText: 2024 #{KERRICK}\n# SPDX-License-Identifier: LGPL-3.0-or-later\n#++\n"
    end
  end

  def test_asks_the_tool_for_other_files_with_the_license_tasks_licenses
    tool = RecordingTool.new(%w[ext/fixture/Cargo.toml .github/ci.yml doc/notes.txt Rakefile])
    in_gem("ext/fixture/Cargo.toml" => "", ".github/ci.yml" => "", "doc/notes.txt" => "", "Rakefile" => "") do
      messages = UnlicensedFiles.new(tool, Repository.new, {}, licensing).license

      assert_equal [
        ["ext/fixture/Cargo.toml", "LGPL-3.0-or-later", KERRICK],
        [".github/ci.yml", "AGPL-3.0-or-later", KERRICK],
        ["doc/notes.txt", "CC-BY-SA-4.0", KERRICK],
      ], tool.annotated
      assert_equal "  Annotating ext/fixture/Cargo.toml with LGPL-3.0-or-later", messages.first
      assert_equal "  Successfully changed header of ext/fixture/Cargo.toml", messages[1]
      assert_equal "  Skipping Rakefile (unknown extension: .)", messages.last
    end
  end

  def test_the_environment_overrides_the_tools_license_and_copyright
    tool = RecordingTool.new(%w[.github/ci.yml doc/notes.txt])
    overrides = { "REUSE_CODE_LICENSE" => "MIT", "REUSE_DOC_LICENSE" => "CC0-1.0", "REUSE_COPYRIGHT" => "Jane Doe" }
    UnlicensedFiles.new(tool, AnonymousRepository.new, overrides, ANY_LICENSING).license

    assert_equal [[".github/ci.yml", "MIT", "Jane Doe"], ["doc/notes.txt", "CC0-1.0", "Jane Doe"]], tool.annotated
  end

  def test_licenses_by_the_licensing_it_is_given
    tool = RecordingTool.new(%w[lib/a.rb .github/ci.yml])
    licensing = Licensing.new(snippets: [], linked: ["lib/"], runtime: "MIT", non_runtime: "Apache-2.0")
    FixtureRepository.open do |repository|
      repository.write("lib/a.rb", "class A; end\n")
      repository.write(".github/ci.yml", "")
      repository.commit(date: "2024-06-01")

      UnlicensedFiles.new(tool, Repository.new, {}, licensing).license

      assert_includes repository.read("lib/a.rb"), "# SPDX-License-Identifier: MIT\n"
      assert_equal [[".github/ci.yml", "Apache-2.0", KERRICK]], tool.annotated
    end
  end

  def test_the_tool_lists_unlicensed_files_and_annotates_those_without_comments
    FixtureRepository.open do |repository|
      repository.write("Cargo.lock", "# lock\n")
      repository.write("notes.txt", "Notes.\n")
      repository.commit(date: "2024-06-01")
      tool = ReuseTool.new

      assert_equal %w[Cargo.lock notes.txt], tool.unlicensed_paths.sort
      tool.annotate("notes.txt", license: "CC-BY-SA-4.0", copyright: "Jane O'Brien <jane@example.com>")

      assert_equal "Notes.\n", repository.read("notes.txt")
      assert_includes repository.read("notes.txt.license"), "Jane O'Brien <jane@example.com>"
    end
  end

  # Commits +files+ in 2024 to an LGPL gem with an extension and runs the
  # block there.
  private def in_gem(files)
    FixtureRepository.open do |repository|
      repository.gemspec(license: "LGPL-3.0-or-later", extensions: ["ext/fixture/extconf.rb"])
      files.each { |path, text| repository.write(path, text) }
      repository.commit(date: "2024-06-01")
      yield repository
    end
  end
end
# REUSE-IgnoreEnd
