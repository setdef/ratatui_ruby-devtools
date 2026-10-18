# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Ensures markdown files have correct SPDX headers.
#
# Open source projects need license headers in every file. REUSE compliance
# requires SPDX format. Adding and updating these headers by hand is tedious.
# Years drift. Contributors are forgotten.
#
# This script processes markdown files. It adds CC-BY-SA-4.0 headers where
# missing. It updates copyright years based on git history. It preserves
# existing contributors.
#
# Run it as part of license:headers:md rake task.
#
# === Example
#
#   ruby tasks/license/headers_md.rb README.md
#   ruby tasks/license/headers_md.rb doc/
#   ruby tasks/license/headers_md.rb  # all .md files
#
# Rules:
# - Ensures file has CC-BY-SA-4.0 license header with YOUR copyright
# - Updates years for EXISTING contributors based on git blame + Co-Authored-By
# - Does NOT add new contributors from git history - only updates existing ones
# - Uses non-code-block lines for year calculation
# - Adds header with YOUR copyright if missing

require_relative "../bump/repository"
require_relative "license_utils"

# You, as git would author your next commit.
YOUR_AUTHOR = Repository.new.author

# Your name for copyright headers.
YOUR_NAME = YOUR_AUTHOR.name

# Your email for copyright headers.
YOUR_EMAIL = YOUR_AUTHOR.email

# Identifiers used to match your contributions in git history.
YOUR_IDENTIFIERS = [YOUR_NAME, YOUR_EMAIL].freeze

# Full copyright string for headers.
YOUR_COPYRIGHT = "#{YOUR_NAME} <#{YOUR_EMAIL}>"

# The SPDX license identifier for markdown documentation.
LICENSE = "CC-BY-SA-4.0"

# Identifies fenced code blocks in markdown content.
#
# Copyright years come from git blame. Code blocks contain pasted content,
# not original prose. Blaming code block lines produces wrong contributors.
# Exclude these ranges when calculating copyright years.
#
# [lines] Array of line strings from the file.
def find_code_blocks(lines)
  blocks = []
  i = 0

  while i < lines.length
    line = lines[i]

    if line =~ /^(````*)(\w*)$/
      fence_marker = $1
      fence_start = i
      re_end = /^#{Regexp.escape(fence_marker)}$/

      j = i + 1
      while j < lines.length
        if lines[j] =~ re_end
          blocks << { start: fence_start, end: j }
          i = j
          break
        end
        j += 1
      end
    end

    i += 1
  end

  blocks
end

# Calculates line ranges outside code blocks.
#
# Copyright years come from git blame. Blaming the entire file includes code
# blocks. This function returns only prose ranges for accurate year lookup.
#
# [lines] Array of line strings from the file.
def get_non_code_line_ranges(lines)
  header_end = 0
  if lines[0]&.include?("<!--")
    (0...(lines.length)).each do |i|
      if lines[i].include?("-->")
        header_end = i + 1
        break
      end
    end
  end

  code_blocks = find_code_blocks(lines)
  non_code_ranges = []
  current_line = header_end

  code_blocks.each do |block|
    if current_line < block[:start]
      non_code_ranges << [current_line + 1, block[:start]]
    end
    current_line = block[:end] + 1
  end

  if current_line < lines.length
    non_code_ranges << [current_line + 1, lines.length]
  end

  non_code_ranges
end

# Extracts existing SPDX header from markdown content.
#
# Files may already have headers. Updating requires parsing existing copyright
# holders and years. This extracts them for comparison and update.
#
# [lines] Array of line strings from the file.
def parse_existing_header(lines)
  return nil unless lines[0]&.include?("<!--")

  header_end = nil
  copyrights = []
  license = nil

  (0...(lines.length)).each do |i|
    line = lines[i]

    if line =~ /SPDX-FileCopyrightText:\s*(\d{4})\s+(.+)$/
      copyrights << { year: $1.to_i, holder: $2.strip }
    # REUSE-IgnoreStart
    elsif line =~ /SPDX-License-Identifier:\s*(.+)$/
      # REUSE-IgnoreEnd
      license = $1.strip
    end

    if line.include?("-->")
      header_end = i
      break
    end
  end

  return nil if header_end.nil?
  return nil if copyrights.empty? && license.nil?

  { end_line: header_end, copyrights:, license: }
end

# Updates or adds SPDX headers for a single markdown file.
#
# Each file needs correct CC-BY-SA-4.0 headers with accurate copyright years.
# Processing involves reading, parsing, querying git, and rewriting. This
# function orchestrates that workflow.
#
# [filepath] Path to the markdown file.
def process_file(filepath)
  content = File.read(filepath)
  lines = content.lines

  non_code_ranges = get_non_code_line_ranges(lines)

  # Get contributors from non-code lines for year lookups
  all_contributors = {}
  non_code_ranges.each do |start_line, end_line|
    range_contributors = LicenseUtils.get_contributors_for_lines(filepath, start_line, end_line)
    range_contributors.each do |contributor, year|
      all_contributors[contributor] = [all_contributors[contributor] || 0, year].max
    end
  end

  your_year = nil
  all_contributors.each do |contributor, year|
    if YOUR_IDENTIFIERS.any? { |id| contributor.include?(id) }
      your_year = [your_year || 0, year].max
    end
  end
  your_year ||= Date.today.year

  existing = parse_existing_header(lines)

  if existing
    # Only update years for EXISTING contributors
    needs_update = false
    updated_copyrights = []

    existing[:copyrights].each do |c|
      git_year = nil
      all_contributors.each do |contributor, year|
        if c[:holder].split.any? { |word| contributor.include?(word) }
          git_year = [git_year || 0, year].max
        end
      end

      if git_year && git_year != c[:year]
        puts "  Updated #{c[:holder].split.first}'s copyright year: #{c[:year]} -> #{git_year}"
        updated_copyrights << { year: git_year, holder: c[:holder] }
        needs_update = true
      else
        updated_copyrights << c
      end
    end

    # Check if YOUR year needs updating
    your_existing = updated_copyrights.find { |c| YOUR_IDENTIFIERS.any? { |id| c[:holder].include?(id) } }
    if your_existing.nil?
      puts "  Adding your copyright"
      updated_copyrights << { year: your_year, holder: YOUR_COPYRIGHT }
      needs_update = true
    end

    if existing[:license] != LICENSE
      puts "  Fixing license: #{existing[:license]} -> #{LICENSE}"
      needs_update = true
    end

    if needs_update
      # REUSE-IgnoreStart
      header_lines = ["<!--\n"]
      updated_copyrights.each do |c|
        header_lines << "  SPDX-FileCopyrightText: #{c[:year]} #{c[:holder]}\n"
      end
      header_lines << "  SPDX-License-Identifier: #{LICENSE}\n"
      header_lines << "-->\n"
      # REUSE-IgnoreEnd

      remaining = lines[(existing[:end_line] + 1)..]
      File.write(filepath, header_lines.join + remaining.join)
      puts "Updated: #{filepath}"
    end
  else
    # No header - add one with YOUR copyright only
    # REUSE-IgnoreStart
    header = "<!--\n  SPDX-FileCopyrightText: #{your_year} #{YOUR_COPYRIGHT}\n  SPDX-License-Identifier: #{LICENSE}\n-->\n"
    # REUSE-IgnoreEnd

    File.write(filepath, header + content)
    puts "Added header: #{filepath}"
  end
end

# Finds markdown files to process.
#
# License automation runs on file sets. Users may specify paths or want all
# files. This handles both cases using git ls-files for tracking.
#
# [paths] Explicit paths to process, or empty for all tracked .md files.
def find_md_files(paths)
  if paths.empty?
    `git ls-files '*.md'`.split("\n")
  else
    paths.flat_map do |path|
      if File.directory?(path)
        `git ls-files '#{path}/**/*.md'`.split("\n")
      else
        path
      end
    end
  end
end

if __FILE__ == $0
  paths = ARGV.empty? ? [] : ARGV
  files = find_md_files(paths)

  files.each do |file|
    process_file(file)
  end
end
