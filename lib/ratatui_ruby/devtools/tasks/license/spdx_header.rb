# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "copyright"
require_relative "renewal"

class SpdxHeader < Data.define(:copyrights, :license) # :nodoc:
  def self.of(author, contributions, license)
    copyrights = if contributions.empty?
      [Copyright.yours(author)]
    else
      contributions.map { |contribution| Copyright.of(contribution) }.sort_by(&:holder)
    end
    new(copyrights:, license:)
  end

  def renewal(contributions, license)
    renewals = copyrights.map { |copyright| copyright.renewal(contributions) }
    renewed_copyrights = renewals.map(&:value)
    notices = renewals.flat_map(&:notices)
    contributions.each do |contribution|
      next if renewed_copyrights.any? { |copyright| copyright.held_by?(contribution.author) }

      notices << "Adding #{contribution.author.name}'s copyright"
      renewed_copyrights << Copyright.of(contribution)
    end
    notices << "Fixing license: #{self.license} -> #{license}" if self.license != license

    Renewal.new(value: with(copyrights: renewed_copyrights, license:), notices:)
  end

  def commented(prefix)
    # REUSE-IgnoreStart
    copyrights.map { |copyright| "#{prefix} SPDX-FileCopyrightText: #{copyright}\n" }.join +
      "#{prefix} SPDX-License-Identifier: #{license}\n"
    # REUSE-IgnoreEnd
  end
end
