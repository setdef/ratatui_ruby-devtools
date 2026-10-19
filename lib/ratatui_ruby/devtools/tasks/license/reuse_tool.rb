# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "open3"

class ReuseTool # :nodoc:
  # The lint report lists files with no copyright and licensing information
  # under a heading of their own, up to the next heading.
  def unlicensed_paths
    listed = false
    `reuse lint 2>&1`.lines.filter_map do |line|
      listed = true if line.include?("no copyright and licensing")
      listed = false if line.start_with?("# ") && !line.include?("copyright")
      line[/^\* (.+)/, 1] if listed
    end
  end

  # Lockfiles and plain text have no comments to hold a header, so they get
  # a .license file beside them.
  def annotate(path, license:, copyright:)
    output, status = Open3.capture2e(
      "reuse", "annotate", "--license", license, "--copyright", copyright,
      "--fallback-dot-license", "--skip-existing", path
    )
    raise "reuse annotate failed for #{path}:\n#{output}" unless status.success?

    output.lines(chomp: true)
  end
end
