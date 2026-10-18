# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rbconfig"

# These scripts still define top-level methods with the same names, so each
# one runs in a process of its own.
class LicenseScript < Data.define(:name) # :nodoc:
  def run(paths)
    system(RbConfig.ruby, File.expand_path(name, __dir__), *paths, exception: true)
  end
end
