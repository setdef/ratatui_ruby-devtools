# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "blame"
require_relative "licensing"

# Source code takes its license from where it lives, and everything below its
# license header counts toward an author's copyright year.
module DirectoryLicensing # :nodoc:
  def initialize(licensing = nil)
    @licensing = licensing
  end

  def covers?(path)
    extensions.include?(File.extname(path).delete_prefix(".")) &&
      directories.any? { |directory| path.start_with?("#{directory}/") }
  end

  def tracked_patterns
    directories.flat_map do |directory|
      extensions.flat_map { |extension| ["#{directory}/*.#{extension}", "#{directory}/**/*.#{extension}"] }
    end
  end

  def license_for(path)
    (@licensing ||= Licensing.current).license_for(path)
  end

  # Editing the license header, as when relicensing, isn't authorship of the
  # file.
  def contributions(path, lines, author)
    Blame.new(path).contributions(header_in(lines).blame_ranges(lines), uncommitted_by: author)
  end

  private def after_header(lines, end_line)
    lines.drop(end_line + 1).drop_while { |line| line.strip.empty? }
  end
end
