# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/license/licensed_file"
require "ratatui_ruby/devtools/tasks/license/markdown_header_syntax"

# REUSE-IgnoreStart
class MarkdownHeadersTest < DevtoolsTest
  KERRICK = "Kerrick Long <me@kerricklong.com>"
  FENCE = "```"

  def test_adds_a_cc_by_sa_header
    FixtureRepository.open do |repository|
      repository.write("doc/guide.md", "# Guide\n\nText.\n")
      repository.commit(date: "2024-06-01")

      assert_equal ["Added header: doc/guide.md"], annotate
      assert_equal "#{header('2024')}# Guide\n\nText.\n", repository.read("doc/guide.md")
    end
  end

  def test_a_prose_edit_renews_the_year
    FixtureRepository.open do |repository|
      repository.write("guide.md", "#{header('2022')}# Guide\n\nText.\n")
      repository.commit(date: "2022-06-01")
      repository.write("guide.md", "#{header('2022')}# Guide\n\nMore text.\n")
      repository.commit(date: "2024-06-01")

      assert_equal ["  Updated Kerrick's copyright year: 2022 -> 2024", "Updated: guide.md"], annotate
    end
  end

  def test_a_code_block_edit_doesnt_renew_the_year
    FixtureRepository.open do |repository|
      repository.write("guide.md", "#{header('2022')}# Guide\n\n#{FENCE}ruby\nputs 1\n#{FENCE}\n")
      repository.commit(date: "2022-06-01")
      repository.write("guide.md", "#{header('2022')}# Guide\n\n#{FENCE}ruby\nputs 2\n#{FENCE}\n")
      repository.commit(date: "2024-06-01")

      assert_empty annotate
    end
  end

  def test_an_uncommitted_prose_edit_credits_the_runner_once
    FixtureRepository.open do |repository|
      repository.write("guide.md", "#{header('2022')}# Guide\n\nText.\n")
      repository.commit(date: "2022-06-01")
      repository.write("guide.md", "#{header('2022')}# Guide\n\nMore text.\n")

      assert_equal ["  Updated Kerrick's copyright year: 2022 -> #{this_year}", "Updated: guide.md"], annotate
      assert_empty annotate
    end
  end

  private def annotate
    LicensedFile.tracked([], MarkdownHeaderSyntax.new).flat_map(&:annotate)
  end

  private def header(year)
    "<!--\n  SPDX-FileCopyrightText: #{year} #{KERRICK}\n  SPDX-License-Identifier: CC-BY-SA-4.0\n-->\n"
  end
end
# REUSE-IgnoreEnd
