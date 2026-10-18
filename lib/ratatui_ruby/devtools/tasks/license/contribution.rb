# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "../bump/repository"

# An author's work on a file, as of the latest year they touched it.
class Contribution < Data.define(:author, :year) # :nodoc:
end
