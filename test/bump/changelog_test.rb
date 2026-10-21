# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/bump/changelog"
require "ratatui_ruby/devtools/tasks/bump/sem_ver"

# REUSE-IgnoreStart
class ChangelogTest < DevtoolsTest
  def test_releases_unreleased_changes_and_links_them
    in_changelog(<<~MARKDOWN) do |changelog|
      # Changelog

      ## [Unreleased]

      ### Added

      - Something new.

      ## [1.0.0] - 2026-01-01

      - Something old.

      [Unreleased]: https://git.sr.ht/~me/gem/refs/HEAD
      [1.0.0]: https://git.sr.ht/~me/gem/refs/v1.0.0
    MARKDOWN
      changelog.release(SemVer.parse("1.1.0"))

      assert_equal <<~MARKDOWN, File.read("CHANGELOG.md")
        # Changelog

        ## [Unreleased]

        ### Added

        ### Changed

        ### Fixed

        ### Removed

        ## [1.1.0] - #{Date.today.iso8601}

        ### Added

        - Something new.

        ## [1.0.0] - 2026-01-01

        - Something old.

        [Unreleased]: https://git.sr.ht/~me/gem/refs/HEAD
        [1.1.0]: https://git.sr.ht/~me/gem/refs/v1.1.0
        [1.0.0]: https://git.sr.ht/~me/gem/refs/v1.0.0
      MARKDOWN
    end
  end

  def test_links_a_release_on_github
    in_changelog(<<~MARKDOWN) do |changelog|
      ## [Unreleased]

      - Something new.

      ## [1.0.0] - 2026-01-01

      [Unreleased]: https://github.com/me/gem/releases/tag/HEAD
      [1.0.0]: https://github.com/me/gem/releases/tag/v1.0.0
    MARKDOWN
      changelog.release(SemVer.parse("1.1.0"))

      assert_equal <<~MARKDOWN, File.read("CHANGELOG.md")[/^\[Unreleased\]:.*/m]
        [Unreleased]: https://github.com/me/gem/tree/HEAD
        [1.1.0]: https://github.com/me/gem/releases/tag/v1.1.0
        [1.0.0]: https://github.com/me/gem/releases/tag/v1.0.0
      MARKDOWN
    end
  end

  def test_says_when_it_cannot_link_a_release
    in_changelog(<<~MARKDOWN) do |changelog|
      ## [Unreleased]

      - Something new.

      [Unreleased]: https://example.com/gem/HEAD
    MARKDOWN
      assert_output(nil, "The changelog's Unreleased link, https://example.com/gem/HEAD, isn't into a GitHub or " \
        "SourceHut project, so 1.1.0 has no link. Add one by hand.\n") do
        changelog.release(SemVer.parse("1.1.0"))
      end

      assert_equal "[Unreleased]: https://example.com/gem/HEAD\n", File.read("CHANGELOG.md")[/^\[Unreleased\]:.*/m]
    end
  end

  def test_releases_a_changelog_with_nothing_released_yet
    in_changelog(<<~MARKDOWN) do |changelog|
      <!--
        SPDX-FileCopyrightText: 2026 Jane Doe <jane@example.com>
        SPDX-License-Identifier: CC-BY-SA-4.0
      -->

      # Changelog

      ## [Unreleased]

      ### Added

      - Initial release of my_gem
    MARKDOWN
      changelog.release(SemVer.parse("0.1.0"))

      assert_equal <<~MARKDOWN, File.read("CHANGELOG.md")
        <!--
          SPDX-FileCopyrightText: 2026 Jane Doe <jane@example.com>
          SPDX-License-Identifier: CC-BY-SA-4.0
        -->

        # Changelog

        ## [Unreleased]

        ### Added

        ### Changed

        ### Fixed

        ### Removed

        ## [0.1.0] - #{Date.today.iso8601}

        ### Added

        - Initial release of my_gem
      MARKDOWN
    end
  end

  # Writes +text+ as CHANGELOG.md in a directory of its own and runs the
  # block there.
  private def in_changelog(text)
    Dir.mktmpdir do |root|
      Dir.chdir(root) do
        File.write("CHANGELOG.md", text)
        yield Changelog.new
      end
    end
  end
end
# REUSE-IgnoreEnd
