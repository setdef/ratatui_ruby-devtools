# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "date"

class Copyright < Data.define(:year, :holder) # :nodoc:
  YOUR_NAME = "Kerrick Long"
  YOUR_EMAIL = "me@kerricklong.com"
  YOUR_IDENTIFIERS = [YOUR_NAME, YOUR_EMAIL].freeze
  YOUR_HOLDER = "#{YOUR_NAME} <#{YOUR_EMAIL}>"

  def self.yours(contributors)
    new(year: latest_year(contributors, YOUR_IDENTIFIERS) || Date.today.year, holder: YOUR_HOLDER)
  end

  # A holder matches a contributor when any word of the holder appears in the
  # contributor's name and email, so "Kerrick Long <...>" matches either name.
  def self.latest_year(contributors, words)
    contributors.select { |contributor| words.any? { |word| contributor.to_s.include?(word) } }.map(&:year).max
  end

  def yours?
    YOUR_IDENTIFIERS.any? { |identifier| holder.include?(identifier) }
  end

  def renewed(contributors)
    latest_year = self.class.latest_year(contributors, holder.split)
    return self unless latest_year && latest_year != year

    puts "  Updated #{holder.split.first}'s copyright year: #{year} -> #{latest_year}"
    with(year: latest_year)
  end

  def to_s
    "#{year} #{holder}"
  end
end
