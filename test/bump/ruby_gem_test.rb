# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/bump/ruby_gem"

class RubyGemTest < DevtoolsTest
  def test_finds_its_gemspec_name_and_version_file
    in_gem("my_gem.gemspec" => "", "lib/my_gem/version.rb" => %(VERSION = "1.2.3-beta.1"\n)) do
      gem = RubyGem.found

      assert_equal RubyGem.new(name: "my_gem", gemspec_file: "my_gem.gemspec", version_file: "lib/my_gem/version.rb"), gem
      assert_equal "1.2.3-beta.1", gem.version.to_s
      assert_instance_of NoCrate, gem.crate
    end
  end

  # A repository whose stable branch holds +text+ as the version file, or
  # has no stable branch when +text+ is nil.
  StableRepository = Data.define(:text) do
    def stable_file(path)
      text if path == "lib/my_gem/version.rb"
    end
  end

  def test_reads_what_stable_released_as_rubygems_orders_it
    in_gem("my_gem.gemspec" => "") do
      gem = RubyGem.found

      assert_equal Gem::Version.new("1.0.0.pre.beta.1"), gem.stable_version(StableRepository.new(text: %(VERSION = "1.0.0-beta.1"\n)))
      assert_equal Gem::Version.new("0.0.1.pre.1"), gem.stable_version(StableRepository.new(text: %(VERSION = "0.0.1.pre.1"\n)))
      assert_nil gem.stable_version(StableRepository.new(text: "# Soon.\n"))
      assert_nil gem.stable_version(StableRepository.new(text: nil))
    end
  end

  def test_nests_the_version_file_of_a_gem_with_a_dash
    in_gem("my_gem-kit.gemspec" => "", "lib/my_gem/kit/version.rb" => "", "lib/other/version.rb" => "") do
      assert_equal "lib/my_gem/kit/version.rb", RubyGem.found.version_file
    end
  end

  def test_falls_back_to_the_first_version_file_in_lib
    in_gem("my_gem.gemspec" => "", "lib/elsewhere/version.rb" => "") do
      assert_equal "lib/elsewhere/version.rb", RubyGem.found.version_file
    end
  end

  def test_keeps_the_conventional_version_file_when_lib_has_none
    in_gem("my_gem.gemspec" => "") do
      assert_equal "lib/my_gem/version.rb", RubyGem.found.version_file
    end
  end

  def test_needs_exactly_one_gemspec_to_find_it
    in_gem do
      error = assert_raises(RatatuiRuby::Devtools::Error) { RubyGem.found }
      assert_match(/No \*\.gemspec found/, error.message)
    end
    in_gem("a.gemspec" => "", "b.gemspec" => "") do
      error = assert_raises(RatatuiRuby::Devtools::Error) { RubyGem.found }
      assert_equal "Multiple gemspecs found: a.gemspec, b.gemspec", error.message
    end
  end

  def test_keeps_what_you_tell_it
    in_gem("a.gemspec" => "", "b.gemspec" => "") do
      gem = RubyGem.found(gemspec_file: "b.gemspec", name: "named", version_file: "lib/named/meta.rb")

      assert_equal RubyGem.new(name: "named", gemspec_file: "b.gemspec", version_file: "lib/named/meta.rb"), gem
    end
  end

  def test_names_itself_after_the_gemspec_you_tell_it
    in_gem("a.gemspec" => "", "b.gemspec" => "") do
      assert_equal "b", RubyGem.found(gemspec_file: "b.gemspec").name
    end
  end

  def test_loads_its_own_gemspec_wherever_another_gem_loaded_one_of_the_same_name
    licenses = %w[MIT Apache-2.0].map do |license|
      in_gem("fixture.gemspec" => %(Gem::Specification.new { |spec| spec.name = "fixture"; spec.license = "#{license}" })) do
        RubyGem.found.spec.license
      end
    end

    assert_equal %w[MIT Apache-2.0], licenses
  end

  # Runs the block in a directory holding +files+.
  private def in_gem(files = {})
    Dir.mktmpdir do |root|
      Dir.chdir(root) do
        files.each do |path, text|
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, text)
        end
        yield
      end
    end
  end
end
