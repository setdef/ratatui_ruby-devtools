# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rake"

module RatatuiRuby
  module Devtools
    # Where devtools' task files run. Imported at the top level, the helpers
    # and constants they define would land on every object in your Rakefile.
    # Here they stay with the tasks that use them, and the tasks can reach
    # whatever the scope offers.
    class TaskScope # :nodoc:
      include Rake::DSL

      def load(dir)
        Dir.glob("#{dir}/*.rake").each { |path| instance_eval(File.read(path), path) }
      end
    end
  end
end
