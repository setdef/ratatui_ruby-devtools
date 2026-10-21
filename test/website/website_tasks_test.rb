# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "minitest/mock"
require "test_helper"
require "ratatui_ruby/devtools/tasks/bump/ruby_gem"
require "ratatui_ruby/devtools/tasks/website_tasks"
require "ratatui_ruby/devtools/tasks/website/website"

class WebsiteTasksTest < DevtoolsTest
  # Records what it was asked to build instead of building it.
  Site = Data.define(:fields, :built) do
    def build = built << fields
  end

  def test_builds_the_site_of_the_gemspec_the_gem_names
    in_gem("a.gemspec" => gemspec("a"), "b.gemspec" => gemspec("b")) do
      built = []
      WebsiteTasks.new(RubyGem.found(gemspec_file: "b.gemspec"))

      Website.stub(:new, -> (**fields) { Site.new(fields:, built:) }) { Rake::Task["website:build"].invoke }

      assert_equal ["b"], built.map { |fields| fields[:project_name] }
    end
  end

  private def gemspec(name)
    %(Gem::Specification.new { |spec| spec.name = "#{name}" })
  end

  private def in_gem(files)
    application = Rake.application
    Dir.mktmpdir do |root|
      Dir.chdir(root) do
        files.each { |path, text| File.write(path, text) }
        Rake.application = Rake::Application.new
        yield
      end
    end
  ensure
    Rake.application = application
  end
end
