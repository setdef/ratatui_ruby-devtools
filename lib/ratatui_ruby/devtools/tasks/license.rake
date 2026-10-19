# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "license/changed_files"
require_relative "license/licensed_file"
require_relative "license/markdown_header_syntax"
require_relative "license/markdown_snippet_syntax"
require_relative "license/rbs_header_syntax"
require_relative "license/rdoc_snippet_syntax"
require_relative "license/ruby_header_syntax"
require_relative "license/rust_header_syntax"
require_relative "license/snippet_file"

namespace :license do
  namespace :headers do
    {
      md: ["Ensure markdown files have correct CC-BY-SA-4.0 headers", MarkdownHeaderSyntax],
      rb: ["Ensure Ruby files have correct SPDX headers", RubyHeaderSyntax],
      rbs: ["Ensure RBS files have correct SPDX headers", RbsHeaderSyntax],
      rs: ["Ensure Rust files have correct SPDX headers", RustHeaderSyntax],
    }.each do |name, (description, syntax)|
      desc description
      task name, [:files] do |_t, args|
        LicensedFile.tracked(args[:files].to_s.split, syntax.new).flat_map(&:annotate).each { |message| puts message }
      end
    end

    desc "Ensure all files have correct license headers"
    task all: %w[md rb rbs rs]
  end

  namespace :snippets do
    {
      md: ["Add MIT-0 SPDX snippet headers to markdown fenced code blocks", MarkdownSnippetSyntax, ""],
      rdoc: ["Add MIT-0 SPDX snippet headers to RDoc code examples in Ruby files", RdocSnippetSyntax, "lib/"],
    }.each do |name, (description, syntax, default)|
      desc description
      task name, [:files] do |_t, args|
        SnippetFile.tracked((args[:files] || default).split, syntax.new).flat_map(&:annotate).each { |message| puts message }
      end
    end

    desc "Add MIT-0 SPDX snippet headers to all code examples"
    task all: %w[md rdoc]
  end

  desc "Run all license tasks (headers + snippets)"
  task all: ["headers:all", "snippets:all"]

  desc "Run license tasks on changed files only (staged + unstaged)"
  task :new do
    ChangedFiles.new(Repository.new).license.each { |message| puts message }
  end
end
