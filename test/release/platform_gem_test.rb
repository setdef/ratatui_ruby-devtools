# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/bump/ruby_gem"
require "ratatui_ruby/devtools/tasks/release/platform_gem"

class PlatformGemTest < DevtoolsTest
  GEMSPEC = <<~RUBY
    Gem::Specification.new do |spec|
      spec.name = "my-gem"
      spec.version = "1.2.3"
      spec.summary = "Fixture"
      spec.authors = ["Fixture"]
      spec.files = ["lib/my_gem.rb"]
      spec.extensions = ["ext/my_gem/extconf.rb"]
    end
  RUBY

  def test_packages_the_binaries_for_each_ruby_into_one_platform_gem
    in_gem do
      assert_output(%r{Built pkg/my-gem-1.2.3-}) { PlatformGem.new(RubyGem.found).build }

      spec = Gem::Package.new(Dir["pkg/*.gem"].first).spec
      assert_equal Gem::Requirement.new(">= 3.3", "< 4.1.dev"), spec.required_ruby_version
      assert_equal %w[lib/my_gem.rb lib/my_gem/3.3/my_gem.bundle lib/my_gem/4.0/my_gem.bundle], spec.files.sort
      assert_empty spec.extensions
    end
  end

  private def in_gem
    Dir.mktmpdir do |root|
      Dir.chdir(root) do
        File.write("my-gem.gemspec", GEMSPEC)
        FileUtils.mkdir_p(%w[lib/my_gem/3.3 lib/my_gem/4.0])
        File.write("lib/my_gem.rb", "")
        File.write("lib/my_gem/3.3/my_gem.bundle", "")
        File.write("lib/my_gem/4.0/my_gem.bundle", "")
        yield
      end
    end
  end
end
