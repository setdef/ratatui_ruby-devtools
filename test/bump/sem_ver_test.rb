# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/bump/sem_ver"

class SemVerTest < DevtoolsTest
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
end
