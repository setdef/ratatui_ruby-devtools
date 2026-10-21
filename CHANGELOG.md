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
- **RBS SPDX headers**: The Ruby header task also wrote headers into `.rbs` files, opening them with a `# frozen_string_literal: true` comment that means nothing in RBS. `rake license:headers:rbs` now writes their headers without it, and `license:headers:all` and `license:new` run it too. A signature loses the comment the next time its header changes.
- **Lockfile Ruby check**: Bundler checks locked gems only against the Ruby that resolves them. A lockfile updated on your newest Ruby could hold gems your oldest supported Ruby can't install, and nothing failed until CI. `rake lint` now catches these gems and prints the `bundle lock` command that relocks them on the oldest Ruby.
- **Link check**: Broken links in your docs fail silently, so your readers find them before you do. `rake doc:check_links` scans your gem's RDoc and Markdown for relative links to files that don't exist and for `file://` URLs that only work on your machine. It asks whether to check web URLs too, and fails when it finds a broken link.
- **Prerelease versions**: `rake bump:exact[1.0.0-rc.1]` sets a SemVer prerelease. Bumping a prerelease releases it when you bump the segment it leads up to, so `rake bump:patch` takes `1.0.0-rc.1` to `1.0.0` instead of skipping to `1.0.1`. A prerelease that isn't valid SemVer, such as `1.0.0-alpha.001`, stops the bump with an error that shows the right form.

### Changed

- **Settings move to `install_gem_tasks!`**: `RatatuiRuby::Devtools.gem_name`, `gemspec_file`, and `version_file`, and their setters, read as settings of devtools rather than of your gem. Pass them to `install_gem_tasks!` instead, as in `RatatuiRuby::Devtools.install_gem_tasks!(gem_name: "my_gem")`, along with the new `non_runtime_license:` and `snippet_paths:`. Devtools now finds your gemspec when it installs the tasks, so a gem with more than one gemspec passes `gemspec_file:` before any task runs.
- **Each version's docs build with its own bundle**: `rake website:build` ran every version's doc tasks with the bundle you built from, so updating devtools or RDoc there changed the docs of every release on your site. Each version now builds with its own Ruby, bundle, and tasks, using RDoc 7.2.0 if it locked an older one. A version whose bundle no longer installs, such as one that locked a yanked gem or names a gem by a relative path, still builds with yours.
- **RDoc 8**: RDoc 8 changed how its HTML formatter starts, so the doc tasks now need RDoc 8.1 or later. Change the `rdoc` development dependency in your gemspec to `"~> 8.1"`, or run `scaffold --update`; until then, Bundler can't install this release beside your gem. RDoc 8 renders your README only as `index.html` but still links `README.md` to `README_md.html`, so `rake rdoc` now writes that page as a redirect to `index.html`.
- **Release branches from 1.0 on**: Minor and major releases happened on trunk, so a patch for an older series had no branch to land on. Once your gem reaches 1.0, `rake bump:minor` and `rake bump:major` create a `release/X.Y` branch, release there, and import the release into trunk. `rake bump:patch` releases on the release branch you have checked out and refuses to run on trunk. Before 1.0, every bump releases on trunk. Every bump now commits for you and stops if your working tree has uncommitted changes. `rake bump:exact` no longer prints a suggested commit message.
- **Snippet copyright notices**: REUSE 3.3 requires copyright notices inside a code snippet to use `SPDX-SnippetCopyrightText`, and recommends a contact address. The scaffolded documentation's snippets now use that tag with your name and email. `rake license:snippets:all` writes new snippets the same way, crediting each author of the snippet's lines, and converts the tag in the snippets your docs already have. Run `scaffold --update` and then `rake license:snippets:all` to pick it up.
- **License for each file**: The license tasks gave `lib/`, `ext/`, and `test/` the LGPL and everything else the AGPL, whatever your gem's license, and gave MIT-0 to examples whose names start with `widget_` or `verify_`. Code apps link, from your gemspec's `require_paths` and `extensions`, now takes the license in your gemspec. Everything else, including tests, `sig/`, and `exe/`, takes AGPL-3.0-or-later, or the `non_runtime_license:` you pass to `install_gem_tasks!`. Examples get MIT-0 only under the path prefixes you pass as `snippet_paths:`, so pass them in your Rakefile before running `rake license:headers:all`, or those examples become AGPL.
- **Scaffolded `bin/setup`**: Installs the bundle in `vendor/bundle` instead of the shared per-user gem directory, so native gems always match the project's Ruby. Run `scaffold --update` to pick it up.

### Fixed

- **Bumping a Rust gem with a dash in its name**: The scaffold puts a gem's crate in `ext/` under the gem's name with underscores, as Cargo wants, but `rake bump:*` looked under the name with its dash. For a gem like `my-gem`, the bump left the crate's `Cargo.toml` and `Cargo.lock` at the old version. It now finds the crate where the scaffold puts it and refreshes the package its `Cargo.toml` names.
- **`rake website:build` ignored `gemspec_file`**: The other tasks read the gemspec you named. The website build read the first `*.gemspec` in your gem's directory instead, so a gem with more than one could get a site titled after the wrong one. It now reads the gemspec you pass as `gemspec_file:`, like the other tasks.
- **Platform gems in your gem's CI**: The scaffolded `build-gems` workflow packaged precompiled gems with `ruby tasks/release/platform_gem.rb`, a script that only exists inside devtools, so the Package job failed. The job now installs your bundle and runs `rake release:platform_gem`, and the gem it builds for Apple Silicon installs on every macOS version. Run `scaffold --update` to pick it up.
- **License tasks in your gem**: The `license:headers:*` and `license:snippets:*` tasks ran their scripts from your gem's own `tasks/license/` directory, which only exists in the gem devtools came from, so they failed with `No such file or directory`. They now run the scripts devtools ships.
- **`rake reuse:fix` credited Kerrick Long**: It annotated every file it fixed with Kerrick Long's copyright, no matter who ran it. It now uses the identity git gives your commits, from `user.name` and `user.email` or the `GIT_AUTHOR_*` variables, and stops with instructions when git doesn't know who you are. `REUSE_COPYRIGHT` still overrides it.
- **`rake reuse:fix` wrote the wrong headers**: It gave every code file AGPL-3.0-or-later, even in `lib/` of an LGPL gem, in the REUSE Tool's header format rather than yours. It also quit at the first `.rbs` file, `Gemfile.lock`, or `.txt` file, which the REUSE Tool can't comment, leaving the files after it bare. On Windows it failed on every file, because the shell there ignores single quotes and split your name at its spaces. Ruby, RBS, Rust, and Markdown files now get the headers the license tasks write, and other code takes the license the license tasks would choose unless you set `REUSE_CODE_LICENSE`. `Gemfile.lock` and plain text get a `.license` file beside them, and the REUSE Tool gets your name without a shell in between.
- **Short and RubyGems-style versions**: A version like `1.2` crashed `rake bump:patch`. A RubyGems-style prerelease like `1.0.0.beta.1` was read as `1.0.0`, so the next bump skipped past the release. `1.2` now bumps as `1.2.0`, and `1.0.0.beta.1` stops the bump with an error asking for `1.0.0-beta.1`.

### Removed

- **`rake reuse:normalize_ruby`**: It moved the bare SPDX lines the REUSE Tool wrote into Ruby files below the magic comment and between `#--` and `#++`. `rake reuse:fix` now writes Ruby headers that way itself, so there is nothing left to normalize.

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