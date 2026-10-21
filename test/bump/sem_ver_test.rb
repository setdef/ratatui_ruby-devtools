# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/bump/sem_ver"

class SemVerTest < DevtoolsTest
  # Each bump from a release and from each kind of prerelease. A labelled
  # bump, such as minor[rc], makes a prerelease of the version the bump
  # would release.
  BUMPS = <<~TABLE
    from          patch  minor  major  minor[rc]   major[beta]
    1.1.3         1.1.4  1.2.0  2.0.0  1.2.0-rc.1  2.0.0-beta.1
    1.2.0-beta.3  1.2.0  1.2.0  2.0.0  1.2.0-rc.1  2.0.0-beta.1
    1.2.0-rc.1    1.2.0  1.2.0  2.0.0  1.2.0-rc.2  2.0.0-beta.1
    2.0.0-beta.1  2.0.0  2.0.0  2.0.0  2.0.0-rc.1  2.0.0-beta.2
  TABLE

  def test_bumps_releases_and_prereleases
    (_, *bumps), *rows = BUMPS.lines.map(&:split)
    bumps = bumps.map { |bump| bump.match(/\A(\w+)(?:\[(\w+)\])?\z/).captures }

    rows.each do |from, *expected|
      bumped = bumps.map { |segment, label| v(from).next(segment.to_sym, label).to_s }

      assert_equal expected, bumped, "from #{from}"
    end
  end

  def test_labels_a_patch_too
    assert_equal "1.1.4-rc.1", SemVer.parse("1.1.3").next(:patch, "rc").to_s
  end

  def test_counts_a_label_that_had_no_number
    assert_equal "1.2.0-beta.1", SemVer.parse("1.2.0-beta").next(:minor, "beta").to_s
  end

  def test_refuses_a_label_that_would_go_backwards
    error = assert_raises(ArgumentError) { SemVer.parse("1.2.0-rc.1").next(:minor, "beta") }

    assert_equal "1.2.0-beta.1 would come before 1.2.0-rc.1. SemVer compares prerelease labels as text, " \
      "so pick a label that sorts after rc.", error.message
  end

  def test_refuses_a_label_that_is_not_semver
    error = assert_raises(ArgumentError) { SemVer.parse("1.1.3").next(:minor, "be ta") }

    assert_match(/1\.2\.0-be ta\.1 has an invalid prerelease/, error.message)
  end

  def test_compares_segments_as_numbers
    assert_operator v("1.9.0"), :<, v("1.10.0")
    assert_operator v("1.2.9"), :<, v("1.3.0")
    assert_operator v("1.99.99"), :<, v("2.0.0")
  end

  def test_puts_a_prerelease_before_its_release
    assert_operator v("1.0.0-rc.9"), :<, v("1.0.0")
    assert_operator v("1.0.0-rc.1"), :>, v("0.99.0")
  end

  def test_compares_numeric_identifiers_as_numbers
    assert_operator v("1.0.0-beta.2"), :<, v("1.0.0-beta.11")
  end

  # SemVer sorts labels alphabetically, by their characters, and knows
  # nothing of what they mean. Alpha, beta, and rc follow each other only
  # because the alphabet happens to agree.
  def test_sorts_labels_alphabetically_not_by_what_they_mean
    assert_operator v("1.0.0-alpha"), :<, v("1.0.0-beta")
    assert_operator v("1.0.0-beta"), :<, v("1.0.0-rc")

    assert_operator v("1.0.0-dev"), :>, v("1.0.0-beta"), "dev usually comes first, but d sorts after b"
    assert_operator v("1.0.0-pre"), :>, v("1.0.0-beta"), "pre usually comes first, but p sorts after b"
    assert_operator v("1.0.0-RC"), :<, v("1.0.0-beta"), "capitals sort before every lowercase letter"
  end

  def test_refuses_beta_after_dev_though_people_release_them_in_that_order
    error = assert_raises(ArgumentError) { v("1.2.0-dev.1").next(:minor, "beta") }

    assert_equal "1.2.0-beta.1 would come before 1.2.0-dev.1. SemVer compares prerelease labels as text, " \
      "so pick a label that sorts after dev.", error.message
  end

  def test_puts_numbers_before_words
    assert_operator v("1.0.0-1"), :<, v("1.0.0-alpha")
    assert_operator v("1.0.0-alpha.1"), :<, v("1.0.0-alpha.beta")
  end

  def test_takes_an_identifier_with_a_hyphen_as_a_word
    assert_operator v("1.0.0-1"), :<, v("1.0.0--1")
  end

  def test_puts_the_prerelease_that_runs_out_first_first
    assert_operator v("1.0.0-alpha"), :<, v("1.0.0-alpha.1")
  end

  def test_equals_the_same_version_however_it_was_written
    assert_equal v("1.2.0"), v("1.2")
    assert_equal v("1.0.0-rc.1"), v("1.0.0-rc.1")
    refute_equal v("1.0.0-rc.1"), v("1.0.0")
  end

  def test_compares_only_with_versions
    refute_equal v("1.0.0"), "1.0.0"
    assert_raises(ArgumentError) { v("1.0.0") < "1.0.0" }
  end

  def test_orders_the_semver_specs_example
    ordered = %w[1.0.0-alpha 1.0.0-alpha.1 1.0.0-alpha.beta 1.0.0-beta 1.0.0-beta.2 1.0.0-beta.11 1.0.0-rc.1 1.0.0]

    assert_equal ordered, ordered.reverse.map { |version| v(version) }.sort.map(&:to_s)
  end

  def test_parses_short_versions_and_refuses_rubygems_prereleases
    assert_equal "1.2.0", SemVer.parse("1.2").to_s

    error = assert_raises(ArgumentError) { SemVer.parse("1.0.0.beta.1") }
    assert_equal "1.0.0.beta.1 is not SemVer. Put the prerelease after a hyphen, like 1.0.0-beta.1.", error.message
    assert_raises(ArgumentError) { SemVer.parse("1.0.0-alpha.001") }
  end

  def test_names_its_tag_as_written
    assert_equal "v1.2.3", SemVer.parse("1.2.3").to_tag
    assert_equal "v1.0.0-beta.1", SemVer.parse("1.0.0-beta.1").to_tag
  end

  def test_orders_as_rubygems_does
    beta = SemVer.parse("1.0.0-beta.1").to_gem_version

    assert_equal Gem::Version.new("1.0.0.pre.beta.1"), beta
    assert_operator beta, :<, SemVer.parse("1.0.0").to_gem_version
    assert_operator beta, :>, SemVer.parse("0.10.3").to_gem_version
  end

  private def v(string)
    SemVer.parse(string)
  end
end
