# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "bump/repository"
require_relative "license/reuse_tool"
require_relative "license/unlicensed_files"

namespace :reuse do
  desc "Run the REUSE Tool to confirm REUSE compliance"
  task :lint do
    sh "reuse lint"
  end

  desc "Add SPDX headers to files missing them (per AGENTS.md standards)"
  task :fix do
    puts "Checking for files missing REUSE headers..."
    overrides = ENV.slice("REUSE_COPYRIGHT", "REUSE_CODE_LICENSE", "REUSE_DOC_LICENSE")
    UnlicensedFiles.new(ReuseTool.new, Repository.new, overrides).license.each { |message| puts message }
  end

  desc "Normalize Ruby files: frozen_string_literal at top, SPDX in #--/#++ block"
  task :normalize_ruby do
    ruby_extensions = %w[rb rake gemspec].freeze
    ruby_files = Dir.glob("**/*.{#{ruby_extensions.join(',')}}")
      .reject { |f| f.start_with?("vendor/", "tmp/", ".") }

    fixed_count = 0
    ruby_files.each do |file|
      content = File.read(file)
      original = content.dup

      # Skip if no SPDX header
      next unless content.match?(/# SPDX-/)

      # Extract components
      frozen = content.match?(/^# frozen_string_literal: true/)
      spdx_match = content.match(/(# SPDX-FileCopyrightText:[^\n]+\n(?:#[^\n]*\n)*# SPDX-License-Identifier:[^\n]+\n)/m)
      next unless spdx_match

      spdx_block = spdx_match[1]

      # Remove existing frozen_string_literal and SPDX block (and any #--/#++)
      cleaned = content
        .sub(/^# frozen_string_literal: true\n+/, "")
        .sub(/^#--\s*\n/, "")
        .sub(spdx_block, "")
        .sub(/^#\+\+\s*\n/, "")
        .sub(/\A\n+/, "") # Remove leading blank lines

      # Rebuild file in correct order: frozen, blank, #--, SPDX, #++, rest
      new_content = ""
      new_content += "# frozen_string_literal: true\n\n" if frozen
      new_content += "#--\n#{spdx_block}#++\n\n"
      new_content += cleaned.sub(/\A\n+/, "") # Ensure no double blank lines

      next unless new_content != original

      File.write(file, new_content)
      puts "  Normalized #{file}"
      fixed_count += 1
    end

    puts fixed_count.zero? ? "All Ruby files properly normalized!" : "Fixed #{fixed_count} files."
  end
end

task(:reuse) { Rake::Task["reuse:lint"].invoke }
