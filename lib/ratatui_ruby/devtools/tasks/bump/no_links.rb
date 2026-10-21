# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# The links of a changelog that has none yet, as the scaffold writes it.
class NoLinks # :nodoc:
  def release(_version)
    self
  end

  # With no links, the history runs to the end of the changelog.
  def start_in(content)
    content.length
  end

  def footer
    ""
  end
end
