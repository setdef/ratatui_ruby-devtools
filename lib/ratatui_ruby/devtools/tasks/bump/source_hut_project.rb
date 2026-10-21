# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# A project on SourceHut, found from its refs link, such as
# https://git.sr.ht/~me/gem/refs/HEAD. SourceHut has no comparison view, so
# each link shows the tree at one ref.
class SourceHutProject < Data.define(:refs) # :nodoc:
  LINK = %r{\A(.*?/refs/)HEAD\z}

  def self.linked_from(link)
    refs = link[LINK, 1]
    new(refs:) if refs
  end

  def unreleased(_version)
    "#{refs}HEAD"
  end

  def release(version)
    "#{refs}v#{version}"
  end
end
