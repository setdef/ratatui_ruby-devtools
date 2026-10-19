# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# Something brought up to date, with a notice for each change made to it.
class Renewal < Data.define(:value, :notices) # :nodoc:
  def self.unchanged(value)
    new(value:, notices: [])
  end

  def changed?
    notices.any?
  end
end
