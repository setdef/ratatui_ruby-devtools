# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "minitest/mock"
require "test_helper"
require "ratatui_ruby/devtools/tasks/bump/rust_crate"

class RustCrateTest < DevtoolsTest
  def test_finds_the_crate_the_scaffold_names_with_underscores
    in_gem("ext/my_gem/Cargo.toml" => %(name = "my_gem"\nversion = "1.2.3"\n)) do
      crate = RustCrate.of("my-gem")

      assert_equal [Manifest.new(path: "ext/my_gem/Cargo.toml", pattern: RustCrate::VERSION)], crate.manifests
      assert_equal "1.2.3", crate.manifests.first.version.to_s
      assert_equal CargoLockfile.new(path: "ext/my_gem/Cargo.lock", dir: "ext/my_gem", name: "my_gem"), crate.lockfile
    end
  end

  def test_finds_a_crate_named_like_the_gem
    in_gem("ext/my-gem/Cargo.toml" => %(name = "my-gem"\nversion = "1.2.3"\n)) do
      assert_equal "my-gem", RustCrate.of("my-gem").lockfile.name
    end
  end

  def test_refreshes_the_package_its_cargo_toml_names
    in_gem("ext/my_gem/Cargo.toml" => %([package]\nname = "my_gem_native"\nversion = "1.2.3"\n)) do
      assert_equal "my_gem_native", RustCrate.of("my-gem").lockfile.name
    end
  end

  def test_a_pure_ruby_gem_has_no_crate
    in_gem("lib/my_gem.rb" => "") do
      crate = RustCrate.of("my-gem")

      assert_instance_of NoCrate, crate
      assert_empty crate.manifests
      assert_nil crate.refresh
    end
  end

  def test_releases_the_native_gems_of_a_crate
    in_gem("ext/my_gem/Cargo.toml" => %(name = "my_gem"\n)) do
      released = []
      release = Data.define(:version, :sha) { define_method(:release) { released << to_h } }

      NativeGemVersion.stub(:new, -> (**fields) { release.new(**fields) }) do
        RustCrate.of("my-gem").release_native_gems(version: "1.2.3", sha: "abc")
        NoCrate.new.release_native_gems(version: "1.2.3", sha: "abc")
      end

      assert_equal [{ version: "1.2.3", sha: "abc" }], released
    end
  end

  private def in_gem(files)
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
