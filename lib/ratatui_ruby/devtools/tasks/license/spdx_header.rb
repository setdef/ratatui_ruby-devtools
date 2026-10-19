# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "copyright"

class SpdxHeader < Data.define(:copyrights, :license) # :nodoc:
  def self.of(author, contributions, license)
    copyrights = if contributions.empty?
      [Copyright.yours(author)]
    else
      contributions.map { |contribution| Copyright.of(contribution) }.sort_by(&:holder)
    end
    new(copyrights:, license:)
  end

  def renewed(contributions, license)
    renewed_copyrights = copyrights.map { |copyright| copyright.renewed(contributions) }
    contributions.each do |contribution|
      next if renewed_copyrights.any? { |copyright| copyright.held_by?(contribution.author) }

      puts "  Adding #{contribution.author.name}'s copyright"
      renewed_copyrights << Copyright.of(contribution)
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
