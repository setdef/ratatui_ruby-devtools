# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "copyright"
require_relative "spdx_header"

# The tags that open a snippet already wrapped, from their first to their last
# line counting from 0, with the notices they hold.
class SnippetOpening < Data.define(:first, :last, :header) # :nodoc:
  # REUSE-IgnoreStart
  COPYRIGHT = /SPDX-(?:Snippet|File)CopyrightText:\s*(\d{4})\s+(.+)$/
  LICENSE = /SPDX-License-Identifier:\s*(\S+)/
  # REUSE-IgnoreEnd

  def self.in(lines, first, last)
    tags = lines[first..last]
    copyrights = tags.grep(COPYRIGHT) { Copyright.new(year: $1.to_i, holder: $2.strip) }
    license = tags.grep(LICENSE) { $1 }.last
    new(first:, last:, header: SpdxHeader.new(copyrights:, license:))
  end

  def span
    first..last
  end
end
