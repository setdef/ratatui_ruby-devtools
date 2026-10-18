# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "blame"

# Source code takes its license from the directory it lives in, and every line
# of it counts toward an author's copyright year.
module DirectoryLicensing # :nodoc:
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
    case path
    when %r{^(lib|sig/ratatui_ruby|ext|test)/}
      "LGPL-3.0-or-later"
    when %r{^(examples|sig/examples)/(widget_|verify_)}
      "MIT-0"
    else
      "AGPL-3.0-or-later"
    end
  end

  def contributions(path, _lines)
    Blame.new(path).contributions
  end

  private def after_header(lines, end_line)
    lines.drop(end_line + 1).drop_while { |line| line.strip.empty? }
  end
end
