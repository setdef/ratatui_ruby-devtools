# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# A file's license header, ending on +end_line+ counting from 0.
class ExistingHeader < Data.define(:header, :end_line) # :nodoc:
  def revise(revision)
    renewal = header.renewal(revision.contributions, revision.license)
    revision.replace(renewal, end_line) if renewal.changed?
  end

  # The lines below the header, as git blame counts them, from 1.
  def blame_ranges(lines)
    return [] if end_line + 1 >= lines.length

    [[end_line + 2, lines.length]]
  end
end
