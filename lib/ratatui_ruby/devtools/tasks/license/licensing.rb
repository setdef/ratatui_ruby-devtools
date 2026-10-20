# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rubygems"

# The gem's own license is about linking, and an app links only the code it
# requires and the extensions it compiles. Code a gem treats as a large
# snippet is free to copy, like the snippets in its docs.
class Licensing < Data.define(:snippets, :linked, :runtime, :non_runtime) # :nodoc:
  SNIPPET = "MIT-0"

  def self.current
    of(
      Gem::Specification.load(RatatuiRuby::Devtools.gemspec_file),
      snippets: RatatuiRuby::Devtools.snippet_paths,
      non_runtime: RatatuiRuby::Devtools.non_runtime_license
    )
  end

  def self.of(spec, snippets:, non_runtime:)
    new(
      snippets:,
      linked: [*spec.require_paths, *spec.extensions.map { |extension| File.dirname(extension) }]
        .map { |directory| "#{directory}/" },
      runtime: spec.licenses.join(" OR "),
      non_runtime:
    )
  end

  def license_for(path)
    if path.start_with?(*snippets)
      SNIPPET
    elsif path.start_with?(*linked)
      runtime
    else
      non_runtime
    end
  end
end
