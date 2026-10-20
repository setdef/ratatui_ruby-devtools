# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

# The Rust extension of a pure Ruby gem, which has none.
class NoCrate # :nodoc:
  def manifests
    []
  end

  def refresh
  end

  def release_native_gems(version:, sha:)
  end
end
