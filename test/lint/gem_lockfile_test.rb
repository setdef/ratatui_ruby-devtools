# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/lint/gem_lockfile"

class GemLockfileTest < DevtoolsTest
  LOCKFILE = GemLockfile.new(specs: [
    Gem::Specification.new { |spec| spec.name = "old"; spec.version = "1.0.0"; spec.required_ruby_version = ">= 3.0" },
    Gem::Specification.new { |spec| spec.name = "new"; spec.version = "2.0.0"; spec.required_ruby_version = ">= 3.4" },
  ])

  def test_names_the_gems_a_ruby_cannot_install
    assert_equal %w[new], LOCKFILE.gems_too_new_for(Gem::Version.new("3.3")).map(&:name)
    assert_empty LOCKFILE.gems_too_new_for(Gem::Version.new("3.4"))
  end

  def test_stops_with_the_command_that_relocks_them_on_that_ruby
    error = assert_raises(SystemExit) do
      assert_output(nil, /new-2.0.0 \(Ruby >= 3.4\).*mise x ruby@3.3 -- bundle lock --update new/m) do
        LOCKFILE.verify(Gem::Version.new("3.3"))
      end
    end
    refute error.success?
    assert_nil LOCKFILE.verify(Gem::Version.new("3.4"))
  end
end
