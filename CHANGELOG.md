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

- **Lockfile Ruby check**: Bundler checks locked gems only against the Ruby that resolves them. A lockfile updated on your newest Ruby could hold gems your oldest supported Ruby can't install, and nothing failed until CI. `rake lint` now catches these gems and prints the `bundle lock` command that relocks them on the oldest Ruby.

### Changed

- **Release branches from 1.0 on**: Minor and major releases happened on trunk, so a patch for an older series had no branch to land on. Once your gem reaches 1.0, `rake bump:minor` and `rake bump:major` create a `release/X.Y` branch, release there, and import the release into trunk. `rake bump:patch` releases on the release branch you have checked out and refuses to run on trunk. Before 1.0, every bump releases on trunk. Every bump now commits for you and stops if your working tree has uncommitted changes. `rake bump:exact` no longer prints a suggested commit message.
- **Scaffolded `bin/setup`**: Installs the bundle in `vendor/bundle` instead of the shared per-user gem directory, so native gems always match the project's Ruby. Run `scaffold --update` to pick it up.

### Fixed

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