# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "copyright"

class SpdxHeader < Data.define(:copyrights, :license) # :nodoc:
  def self.of(author, contributors, license)
    new(copyrights: [Copyright.of(author, contributors)], license:)
  end

  def renewed(author, contributors, license)
    renewed_copyrights = copyrights.map { |copyright| copyright.renewed(contributors) }
    unless renewed_copyrights.any? { |copyright| copyright.held_by?(author) }
      puts "  Adding your copyright"
      renewed_copyrights << Copyright.of(author, contributors)
    end
    puts "  Fixing license: #{self.license} -> #{license}" if self.license != license

    with(copyrights: renewed_copyrights, license:)
  end

  def commented(prefix)
    # REUSE-IgnoreStart
    copyrights.map { |copyright| "#{prefix} SPDX-FileCopyrightText: #{copyright}\n" }.join +
      "#{prefix} SPDX-License-Identifier: #{license}\n"
    # REUSE-IgnoreEnd
  end
end
