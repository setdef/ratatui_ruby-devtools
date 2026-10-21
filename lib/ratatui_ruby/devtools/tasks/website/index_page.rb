# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "erb"

# Landing page for multi-version documentation portals.
#
# Documentation websites need a version picker. Users land on the portal
# and choose their version. Without a landing page, they'd need to guess
# the URL.
#
# This class generates an index page with version links and optional
# branding. It marks the newest tagged release as "(latest)".
#
# Use it to build the root <tt>index.html</tt> for documentation portals.
class IndexPage
  # Creates an IndexPage.
  #
  # Marks the newest Tagged version as latest for display.
  #
  # [versions] Array of Version objects.
  # [branding] Optional hash of branding overrides for the template.
  def initialize(versions, branding: {})
    @versions = versions
    @branding = branding

    latest_version = @versions.find { |v| v.is_a?(Tagged) }
    latest_version.is_latest = true if latest_version
  end

  # Renders the landing page HTML to a file.
  #
  # Uses an ERB template with version links and branding.
  #
  # [path] Output file path.
  # [project_name] Project name for page title.
  def publish_to(path, project_name:)
    puts "Generating index page..."

    template_path = File.expand_path("../resources/index.html.erb", __dir__)
    template = File.read(template_path)

    html_content = ERB.new(template).result_with_hash(versions: @versions, branding: @branding, project_name:)

    File.write(path, html_content)
  end
end
