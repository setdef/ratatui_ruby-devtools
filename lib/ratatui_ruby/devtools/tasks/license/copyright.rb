# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "date"

class Copyright < Data.define(:year, :holder) # :nodoc:
  def self.of(author, contributions)
    new(year: latest_year(contributions, [author.name, author.email]) || Date.today.year, holder: author.to_s)
  end

  # A holder matches an author when any word of the holder appears in the
  # author's name and email, so "Jane Doe <...>" matches either name.
  def self.latest_year(contributions, words)
    contributions.select { |contribution| words.any? { |word| contribution.author.to_s.include?(word) } }
      .map(&:year).max
  end

  def held_by?(author)
    [author.name, author.email].any? { |identifier| holder.include?(identifier) }
  end

  # Git can know less than the notice does, as when history was rewritten or
  # the work came from elsewhere.
  def renewed(contributions)
    latest_year = self.class.latest_year(contributions, holder.split)
    return self unless latest_year && latest_year > year

    puts "  Updated #{holder.split.first}'s copyright year: #{year} -> #{latest_year}"
    with(year: latest_year)
  end

  def to_s
    "#{year} #{holder}"
  end
end
