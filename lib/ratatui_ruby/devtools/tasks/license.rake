# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

namespace :license do
  namespace :headers do
    desc "Ensure markdown files have correct CC-BY-SA-4.0 headers"
    task :md, [:files] do |_t, args|
      files = args[:files] || ""
      ruby File.expand_path("license/headers_md.rb", __dir__), *files.split
    end

    desc "Ensure Ruby files have correct SPDX headers"
    task :rb, [:files] do |_t, args|
      files = args[:files] || ""
      ruby File.expand_path("license/headers_rb.rb", __dir__), *files.split
    end

    desc "Ensure Rust files have correct SPDX headers"
    task :rs, [:files] do |_t, args|
      files = args[:files] || ""
      ruby File.expand_path("license/headers_rs.rb", __dir__), *files.split
    end

    desc "Ensure all files have correct license headers"
    task :all do
      Rake::Task["license:headers:md"].invoke
      Rake::Task["license:headers:rb"].invoke
      Rake::Task["license:headers:rs"].invoke
    end
  end

  namespace :snippets do
    desc "Add MIT-0 SPDX snippet headers to markdown fenced code blocks"
    task :md, [:files] do |_t, args|
      files = args[:files] || ""
      ruby File.expand_path("license/snippets_md.rb", __dir__), *files.split
    end

    desc "Add MIT-0 SPDX snippet headers to RDoc code examples in Ruby files"
    task :rdoc, [:files] do |_t, args|
      files = args[:files] || "lib/"
      ruby File.expand_path("license/snippets_rdoc.rb", __dir__), *files.split
    end

    desc "Add MIT-0 SPDX snippet headers to all code examples"
    task :all do
      Rake::Task["license:snippets:md"].invoke
      Rake::Task["license:snippets:rdoc"].invoke
    end
  end

  desc "Run all license tasks (headers + snippets)"
  task all: ["headers:all", "snippets:all"]

  desc "Run license tasks on changed files only (staged + unstaged)"
  task :new do
    require_relative "license/changed_files"

    ChangedFiles.new(Repository.new).license
  end
end
