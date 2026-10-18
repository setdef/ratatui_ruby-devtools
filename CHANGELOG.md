<!--
  SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased]

### Added

- **Rust SPDX headers**: Rust files in `ext/` had no license task, so you annotated them by hand and a wrong license slipped through easily. `rake license:headers:rs` now writes their SPDX headers, and `license:headers:all` and `license:new` run it too.
- **Lockfile Ruby check**: Bundler checks locked gems only against the Ruby that resolves them. A lockfile updated on your newest Ruby could hold gems your oldest supported Ruby can't install, and nothing failed until CI. `rake lint` now catches these gems and prints the `bundle lock` command that relocks them on the oldest Ruby.
- **Prerelease versions**: `rake bump:exact[1.0.0-rc.1]` sets a SemVer prerelease. Bumping a prerelease releases it when you bump the segment it leads up to, so `rake bump:patch` takes `1.0.0-rc.1` to `1.0.0` instead of skipping to `1.0.1`. A prerelease that isn't valid SemVer, such as `1.0.0-alpha.001`, stops the bump with an error that shows the right form.

### Changed

- **Release branches from 1.0 on**: Minor and major releases happened on trunk, so a patch for an older series had no branch to land on. Once your gem reaches 1.0, `rake bump:minor` and `rake bump:major` create a `release/X.Y` branch, release there, and import the release into trunk. `rake bump:patch` releases on the release branch you have checked out and refuses to run on trunk. Before 1.0, every bump releases on trunk. Every bump now commits for you and stops if your working tree has uncommitted changes. `rake bump:exact` no longer prints a suggested commit message.
- **Scaffolded `bin/setup`**: Installs the bundle in `vendor/bundle` instead of the shared per-user gem directory, so native gems always match the project's Ruby. Run `scaffold --update` to pick it up.

### Fixed

- **License tasks in your gem**: The `license:headers:*` and `license:snippets:*` tasks ran their scripts from your gem's own `tasks/license/` directory, which only exists in the gem devtools came from, so they failed with `No such file or directory`. They now run the scripts devtools ships.
- **`rake reuse:fix` credited Kerrick Long**: It annotated every file it fixed with Kerrick Long's copyright, no matter who ran it. It now uses the identity git gives your commits, from `user.name` and `user.email` or the `GIT_AUTHOR_*` variables, and stops with instructions when git doesn't know who you are. `REUSE_COPYRIGHT` still overrides it.
- **Short and RubyGems-style versions**: A version like `1.2` crashed `rake bump:patch`. A RubyGems-style prerelease like `1.0.0.beta.1` was read as `1.0.0`, so the next bump skipped past the release. `1.2` now bumps as `1.2.0`, and `1.0.0.beta.1` stops the bump with an error asking for `1.0.0-beta.1`.

### Removed

## [0.2.1] - 2026-02-16

### Added

### Changed

### Fixed

### Removed

## [0.2.0] - 2026-02-16

### Added

### Changed

### Fixed

### Removed

## [0.1.3] - 2026-02-02

### Added

### Changed

### Fixed

### Removed

## [0.1.2] - 2026-02-02

### Added

### Changed

### Fixed

### Removed

## [0.1.1] - 2026-01-26

### Added

- Multi-version documentation website builder: `install_website_tasks!` generates
  documentation portals with version dropdown menus. Discovers versions from git
  tags, builds RDoc for each in isolation, and creates a landing page with
  branding support.

### Changed

### Fixed

### Removed

## [0.1.0] - 2026-01-08

### Added

- Initial release of `ratatui_ruby-devtools`
- Rake tasks: `lint`, `lint:fix`, `reuse`, `license`, `bump`
- Executables: `agent_rake`, `consolidate_md`, `hbs`, `announce`
- Templates for scaffolding new ecosystem gems
- Auto-discovery of gem configuration from `*.gemspec`
- Conditional Cargo/Rust task support for gems with native extensions

### Added

### Changed

### Fixed

### Removed

[Unreleased]: https://git.sr.ht/~kerrick/ratatui_ruby-devtools/refs/HEAD
[0.2.1]: https://git.sr.ht/~kerrick/ratatui_ruby-devtools/refs/v0.2.1
[0.2.0]: https://git.sr.ht/~kerrick/ratatui_ruby-devtools/refs/v0.2.0
[0.1.3]: https://git.sr.ht/~kerrick/ratatui_ruby-devtools/refs/v0.1.3
[0.1.2]: https://git.sr.ht/~kerrick/ratatui_ruby-devtools/refs/v0.1.2
[0.1.1]: https://git.sr.ht/~kerrick/ratatui_ruby-devtools/refs/v0.1.1
[0.1.0]: https://git.sr.ht/~kerrick/ratatui_ruby-devtools/refs/v0.1.0