# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# A project on GitHub, found from any link into it, such as
# https://github.com/me/gem/releases/tag/HEAD.
class GitHubProject < Data.define(:url) # :nodoc:
  LINK = %r{\A(https://github\.com/[^/]+/[^/]+)/}

  def self.linked_from(link)
    url = link[LINK, 1]
    new(url:) if url
  end

  # Readers browse the code as it stands, rather than read a comparison.
  def unreleased(_version)
    "#{url}/tree/HEAD"
  end

  def release(version)
    "#{url}/releases/tag/v#{version}"
  end
end
