# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/license/licensed_file"
require "ratatui_ruby/devtools/tasks/license/ruby_header_syntax"
require "ratatui_ruby/devtools/tasks/license/rust_header_syntax"

# REUSE-IgnoreStart
class RubyHeadersTest < DevtoolsTest
  KERRICK = "Kerrick Long <me@kerricklong.com>"
  JANE = FixtureRepository::Person.new(name: "Jane Doe", email: "jane@example.com")

  def test_adds_a_header_below_the_magic_comment
    messages = in_gem("lib/a.rb" => "# frozen_string_literal: true\n\nclass A; end\n") { annotate }

    assert_equal ["Added header: lib/a.rb"], messages
    assert_equal "#{header("2024 #{KERRICK}", license: 'LGPL-3.0-or-later')}class A; end\n", @files["lib/a.rb"]
  end

  def test_adds_the_magic_comment_a_file_lacks
    in_gem("lib/b.rb" => "class B; end\n") { annotate }

    assert_equal "#{header("2024 #{KERRICK}", license: 'LGPL-3.0-or-later')}class B; end\n", @files["lib/b.rb"]
  end

  def test_leaves_a_correct_header_alone
    text = "#{header("2024 #{KERRICK}", license: 'LGPL-3.0-or-later')}class C; end\n"
    messages = in_gem("lib/c.rb" => text) { annotate }

    assert_empty messages
    assert_equal text, @files["lib/c.rb"]
  end

  def test_fixes_the_license
    messages = in_gem("lib/d.rb" => "#{header("2024 #{KERRICK}", license: 'AGPL-3.0-or-later')}class D; end\n") { annotate }

    assert_equal ["  Fixing license: AGPL-3.0-or-later -> LGPL-3.0-or-later", "Updated: lib/d.rb"], messages
    assert_equal "#{header("2024 #{KERRICK}", license: 'LGPL-3.0-or-later')}class D; end\n", @files["lib/d.rb"]
  end

  def test_renews_the_year_of_the_last_commit
    messages = in_gem("lib/e.rb" => "#{header("2020 #{KERRICK}", license: 'LGPL-3.0-or-later')}class E; end\n") { annotate }

    assert_equal ["  Updated Kerrick's copyright year: 2020 -> 2024", "Updated: lib/e.rb"], messages
  end

  def test_never_moves_a_year_backwards
    text = "#{header("2025 #{KERRICK}", license: 'LGPL-3.0-or-later')}class C; end\n"
    messages = in_gem("lib/c.rb" => text) { annotate }

    assert_empty messages
    assert_equal text, @files["lib/c.rb"]
  end

  def test_keeps_notices_git_cant_see_and_adds_the_author_it_can
    in_gem("lib/f.rb" => "#{header('2019 Jane Doe <jane@example.com>', license: 'LGPL-3.0-or-later')}class F; end\n") { annotate }

    assert_equal "#{header('2019 Jane Doe <jane@example.com>', "2024 #{KERRICK}", license: 'LGPL-3.0-or-later')}" \
      "class F; end\n", @files["lib/f.rb"]
  end

  def test_adds_the_magic_comment_above_an_existing_header
    in_gem("lib/g.rb" => "#--\n# SPDX-FileCopyrightText: 2024 #{KERRICK}\n# SPDX-License-Identifier: MIT\n#++\n\nclass G; end\n") do
      annotate
    end

    assert_equal "#{header("2024 #{KERRICK}", license: 'LGPL-3.0-or-later')}class G; end\n", @files["lib/g.rb"]
  end

  def test_replaces_a_header_without_its_closing_marker_up_to_its_last_tag
    in_gem("lib/i.rb" => "# SPDX-FileCopyrightText: 2024 #{KERRICK}\n# SPDX-License-Identifier: MIT\n\nclass I; end\n") do
      annotate
    end

    assert_equal "#{header("2024 #{KERRICK}", license: 'LGPL-3.0-or-later')}class I; end\n", @files["lib/i.rb"]
  end

  def test_credits_the_runner_for_a_file_with_no_lines
    in_gem("lib/empty.rb" => "") { annotate }

    assert_equal header("#{this_year} #{KERRICK}", license: "LGPL-3.0-or-later"), @files["lib/empty.rb"]
  end

  def test_licenses_tests_under_the_agpl
    in_gem("test/a_test.rb" => "class ATest; end\n") { annotate }

    assert_equal "#{header("2024 #{KERRICK}", license: 'AGPL-3.0-or-later')}class ATest; end\n", @files["test/a_test.rb"]
  end

  def test_relicensing_a_header_doesnt_renew_its_year
    FixtureRepository.open do |repository|
      repository.gemspec(license: "LGPL-3.0-or-later")
      repository.write("lib/a.rb", "#{header("2022 #{KERRICK}", license: 'AGPL-3.0-or-later')}class A; end\n")
      repository.commit(date: "2022-06-01")
      repository.write("lib/a.rb", "#{header("2022 #{KERRICK}", license: 'LGPL-3.0-or-later')}class A; end\n")
      repository.commit(date: "2024-06-01")

      assert_empty annotate
    end
  end

  def test_credits_an_uncommitted_edit_to_the_runner_once
    FixtureRepository.open do |repository|
      repository.gemspec(license: "LGPL-3.0-or-later")
      repository.write("lib/a.rb", "#{header("2022 #{KERRICK}", license: 'LGPL-3.0-or-later')}class A\n  def a = 1\nend\n")
      repository.commit(date: "2022-06-01")
      repository.write("lib/a.rb", repository.read("lib/a.rb").sub("def a = 1", "def a = 2"))

      assert_equal ["  Updated Kerrick's copyright year: 2022 -> #{this_year}", "Updated: lib/a.rb"], annotate
      assert_empty annotate
    end
  end

  def test_credits_only_the_people_whose_work_is_in_a_file
    runner = FixtureRepository::Person.new(name: "Runner", email: "runner@example.com")
    FixtureRepository.open(runner:) do |repository|
      repository.gemspec(license: "LGPL-3.0-or-later")
      jane_header = header("2022 Jane Doe <jane@example.com>", license: "LGPL-3.0-or-later")
      repository.write("lib/untouched.rb", "#{jane_header}class Untouched; end\n")
      repository.write("lib/edited.rb", "#{jane_header}class Edited; end\n")
      repository.commit(date: "2022-06-01", author: JANE)
      repository.write("lib/edited.rb", "#{jane_header}class Edited\n  def runner = 1\nend\n")

      assert_equal ["  Adding Runner's copyright", "Updated: lib/edited.rb"], annotate
      assert_equal "#{jane_header}class Untouched; end\n", repository.read("lib/untouched.rb")
      assert_includes repository.read("lib/edited.rb"), "# SPDX-FileCopyrightText: #{this_year} Runner <runner@example.com>\n"
    end
  end

  def test_credits_commit_authors_but_not_co_authors
    FixtureRepository.open do |repository|
      repository.gemspec(license: "LGPL-3.0-or-later")
      repository.write("lib/a.rb", "class A; end\n")
      repository.commit(date: "2024-06-01", message: "Add A\n\nCo-Authored-By: Claude <noreply@anthropic.com>")
      annotate

      assert_equal "#{header("2024 #{KERRICK}", license: 'LGPL-3.0-or-later')}class A; end\n", repository.read("lib/a.rb")
    end
  end

  def test_skips_a_named_file_in_another_language
    in_gem("lib/a.rb" => "class A; end\n") do
      assert_empty LicensedFile.tracked(["lib/a.rb"], RustHeaderSyntax.new(licensing)).flat_map(&:annotate)
    end

    assert_equal "class A; end\n", @files["lib/a.rb"]
  end

  # Commits +files+ in 2024 to an LGPL gem, runs the block there, and keeps
  # what the files hold afterwards in @files.
  private def in_gem(files)
    result = nil
    FixtureRepository.open do |repository|
      repository.gemspec(license: "LGPL-3.0-or-later")
      files.each { |path, text| repository.write(path, text) }
      repository.commit(date: "2024-06-01")
      result = yield
      @files = files.keys.to_h { |path| [path, repository.read(path)] }
    end
    result
  end

  private def annotate(paths = [])
    LicensedFile.tracked(paths, RubyHeaderSyntax.new(licensing)).flat_map(&:annotate)
  end

  private def header(*copyrights, license:)
    tags = copyrights.map { |copyright| "# SPDX-FileCopyrightText: #{copyright}\n" }.join
    "# frozen_string_literal: true\n\n#--\n#{tags}# SPDX-License-Identifier: #{license}\n#++\n\n"
  end
end
# REUSE-IgnoreEnd
