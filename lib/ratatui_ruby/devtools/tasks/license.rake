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
      ruby "tasks/license/headers_md.rb #{files}"
    end

    desc "Ensure Ruby files have correct SPDX headers"
    task :rb, [:files] do |_t, args|
      files = args[:files] || ""
      ruby "tasks/license/headers_rb.rb #{files}"
    end

    desc "Ensure Rust files have correct SPDX headers"
    task :rs, [:files] do |_t, args|
      files = args[:files] || ""
      ruby "tasks/license/headers_rs.rb #{files}"
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
      ruby "tasks/license/snippets_md.rb #{files}"
    end

    desc "Add MIT-0 SPDX snippet headers to RDoc code examples in Ruby files"
    task :rdoc, [:files] do |_t, args|
      files = args[:files] || "lib/"
      ruby "tasks/license/snippets_rdoc.rb #{files}"
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
    require_relative "license/licensed_file"
    require_relative "license/ruby_header_syntax"
    require_relative "license/rust_header_syntax"

    repository = Repository.new
    markdown = repository.changed_files.select { |path| path.end_with?(".md") }
    ruby = LicensedFile.changed(RubyHeaderSyntax.new, repository:)
    rust = LicensedFile.changed(RustHeaderSyntax.new, repository:)

    if markdown.empty? && ruby.empty? && rust.empty?
      puts "No changed Markdown, Ruby, or Rust files to process"
    else
      unless markdown.empty?
        puts "Processing #{markdown.count} changed .md file(s)..."
        Rake::Task["license:headers:md"].invoke(markdown.join(" "))
        Rake::Task["license:headers:md"].reenable
        Rake::Task["license:snippets:md"].invoke(markdown.join(" "))
        Rake::Task["license:snippets:md"].reenable
      end

      unless ruby.empty?
        puts "Processing #{ruby.count} changed Ruby file(s)..."
        ruby.each(&:annotate)

        # RDoc examples only appear in the documented library.
        library = ruby.map(&:path).select { |path| path.start_with?("lib/") && path.end_with?(".rb") }
        unless library.empty?
          Rake::Task["license:snippets:rdoc"].invoke(library.join(" "))
          Rake::Task["license:snippets:rdoc"].reenable
        end
      end

      unless rust.empty?
        puts "Processing #{rust.count} changed Rust file(s)..."
        rust.each(&:annotate)
      end
    end
  end
end
