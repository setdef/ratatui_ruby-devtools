# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rubocop/rake_task"
require "rubycritic/rake_task"
require "inch/rake"

RuboCop::RakeTask.new

# Run rubycritic in a shell to prevent it from exiting the rake process
task :rubycritic do
  paths = []
  paths << "exe" if Dir.exist?("exe")
  paths << "lib" if Dir.exist?("lib")
  paths << "sig" if Dir.exist?("sig")
  sh "bundle exec rubycritic --no-browser #{paths.join(' ')}" unless paths.empty?
end

Inch::Rake::Suggest.new("doc:suggest", "exe/**/*.rb", "lib/**/*.rb", "sig/**/*.rbs") do |suggest|
  suggest.args << ""
end

namespace :lint do
  task :safe_rdoc_coverage do
    if Rake::Task.task_defined?("rdoc:coverage")
      sh "bundle exec rake rdoc:coverage"
    else
      puts "rdoc:coverage task not defined, skipping"
    end
  end

  desc "Check that every locked gem installs on the oldest supported Ruby"
  task :lockfile_ruby do
    require_relative "lint/gem_lockfile"
    require_relative "lint/supported_rubies"

    GemLockfile.current.verify(SupportedRubies.of(RatatuiRuby::Devtools.gemspec_file).oldest)
  end

  # Build dynamic task lists based on what's available
  docs_tasks = %w[rubycritic]
  docs_tasks.unshift("autodoc") if Rake::Task.task_defined?("autodoc")
  docs_tasks << "safe_rdoc_coverage" if Rake::Task.task_defined?("rdoc:coverage")

  code_tasks = %w[rubocop rubycritic lockfile_ruby]
  code_tasks += %w[cargo:fmt cargo:clippy cargo:test] if Dir.exist?("ext")

  task docs: docs_tasks
  task code: code_tasks
  task all: %w[docs code]

  namespace :fix do
    desc "Auto-fix RuboCop offenses (most aggressive)"
    task :rubocop do
      sh "bundle exec rubocop --autocorrect-all"
    end

    if Dir.exist?("ext")
      desc "Auto-fix Clippy warnings (most aggressive: --fix --allow-dirty --allow-staged)"
      task :clippy do
        ext_dirs = Dir.glob("ext/*").select { |d| File.directory?(d) && File.exist?("#{d}/Cargo.toml") }
        ext_dirs.each do |dir|
          sh "cd #{dir} && cargo clippy --fix --allow-dirty --allow-staged"
        end
      end
    end

    # Build dynamic fix:all task
    fix_all_tasks = %w[lint:fix:rubocop]
    fix_all_tasks.insert(1, "lint:fix:clippy") if Dir.exist?("ext")

    desc "Run all auto-fix tasks"
    task all: fix_all_tasks
  end
end

desc "Run all lint auto-fix tasks"
task("lint:fix") { Rake::Task["lint:fix:all"].invoke }

# Aliases for convenience
task "rubocop:autocorrect_all" => "lint:fix:rubocop"

desc "Run all lint tasks"
task(:lint) { Rake::Task["lint:all"].invoke }
