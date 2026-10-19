# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# The license header a file doesn't have yet.
class MissingHeader < Data.define # :nodoc:
  def revise(revision)
    revision.add
  end

  # Every line, for a file with no header to leave out.
  def blame_ranges(_lines)
    nil
  end
end
