# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/website/source_tree"

class SourceTreeTest < DevtoolsTest
  # Runs no commands. It records each one in the tree, and fails those the
  # tree's +failing+ file names.
  class ScriptedTree < SourceTree
    def run(command, _env = {})
      File.write(File.join(path, "commands"), "#{command}\n", mode: "a")
      failing = File.join(path, "failing")
      !(File.exist?(failing) && File.read(failing).lines.map(&:chomp).include?(command))
    end

    def commands
      File.readlines(File.join(path, "commands"), chomp: true)
    end
  end

  def test_builds_with_its_own_bundle_when_it_installs
    in_site do |source|
      File.write(File.join(source, "Gemfile.lock"), "GEM\n  specs:\n    rdoc (7.2.0)\n")
      tree = ScriptedTree.new(path: source)

      assert_same tree, tree.buildable("7.2.0")
      assert_equal ["bundle install --quiet"], tree.commands
      assert_equal "source \"https://rubygems.org\"\n", File.read(File.join(source, "Gemfile"))
    end
  end

  def test_locks_the_rdoc_floor_when_it_locked_an_older_rdoc
    in_site do |source|
      File.write(File.join(source, "Gemfile.lock"), "GEM\n  specs:\n    rdoc (7.0.3)\n")
      tree = ScriptedTree.new(path: source)

      assert_same tree, tree.buildable("7.2.0")
      assert_equal ["bundle lock --update rdoc", "bundle install --quiet"], tree.commands
      assert_includes File.read(File.join(source, "Gemfile")), %(\ngem "rdoc", "7.2.0"\n)
    end
  end

  def test_builds_with_the_sites_bundle_when_its_own_wont_install
    in_site do |source|
      File.write(File.join(source, "failing"), "bundle install --quiet\n")
      tree = nil

      assert_output("  Its own bundle won't install, so it builds with this one...\n") do
        tree = ScriptedTree.new(path: source).buildable("7.2.0")
      end
      assert_equal HostedSourceTree.new(path: source, gemfile: File.absolute_path("Gemfile")), tree
      assert_equal "task :site\n", File.read(File.join(source, "Rakefile"))
    end
  end

  def test_builds_with_the_sites_bundle_when_the_rdoc_floor_wont_lock
    in_site do |source|
      File.write(File.join(source, "failing"), "bundle lock --update rdoc\n")
      tree = ScriptedTree.new(path: source)

      assert_output(/won't install/) { assert_instance_of HostedSourceTree, tree.buildable("7.2.0") }
      assert_equal ["bundle lock --update rdoc"], tree.commands
    end
  end

  def test_a_hosted_tree_runs_in_its_source_with_the_sites_bundle
    in_site do |source|
      tree = HostedSourceTree.adopt(source)

      assert tree.run(%(ruby -e 'File.write("seen", ENV.values_at("BUNDLE_GEMFILE", "BUNDLE_LOCKFILE").join(" "))'))
      assert_equal "#{File.absolute_path('Gemfile')} #{File.absolute_path('Gemfile.lock')}", File.read(File.join(source, "seen"))
      assert_equal "# site task\n", File.read(File.join(source, "tasks", "site.rake"))
    end
  end

  def test_a_hosted_tree_needs_no_tasks_directory
    in_site(tasks: false) do |source|
      HostedSourceTree.adopt(source)

      refute Dir.exist?(File.join(source, "tasks"))
    end
  end

  # Makes a site's gem the working directory, with a version's source beside
  # it, and runs the block with the source's path.
  private def in_site(tasks: true)
    Dir.mktmpdir do |root|
      Dir.chdir(root) do
        File.write("Gemfile", "source \"https://rubygems.org\"\n")
        File.write("Rakefile", "task :site\n")
        if tasks
          FileUtils.mkdir_p("tasks")
          File.write("tasks/site.rake", "# site task\n")
        end
        source = Dir.mktmpdir("source", root)
        File.write(File.join(source, "Gemfile"), "source \"https://rubygems.org\"\n")
        yield source
      end
    end
  end
end
