<!--
  SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->
# ratatui_ruby-devtools

[![
CI](https://github.com/setdef/ratatui_ruby-devtools/actions/workflows/ci.yml/badge.svg?branch=stable)](https://github.com/setdef/ratatui_ruby-devtools/actions/workflows/ci.yml) [![
License](https://img.shields.io/badge/License-AGPL--3.0--or--later-a2c93e)](https://spdx.org/licenses/AGPL-3.0-or-later.html) [![
Gem Version](https://img.shields.io/gem/v/ratatui_ruby-devtools)](https://rubygems.org/gems/ratatui_ruby-devtools) [![
Issues](https://img.shields.io/github/issues/setdef/ratatui_ruby-devtools)](https://github.com/setdef/ratatui_ruby-devtools/issues)


## Introduction

**ratatui_ruby-devtools** provides shared development tooling for the [RatatuiRuby ecosystem](https://www.ratatui-ruby.dev). It includes Rake tasks, linters, license enforcement, and build tooling used across all RatatuiRuby gems.

This is a **non-runtime** gem. It provides build tooling—not application features. Add it to your `:development` group only.

---

## Quick Links

### The Ecosystem

**RatatuiRuby:** [Core engine](https://github.com/setdef/RatatuiRuby) • **Rooibos:** [MVU architecture](https://www.rooibos.run) • **Kit:** [Component architecture](https://git.sr.ht/~kerrick/ratatui_ruby-kit) (Planned) • **DSL:** [Glimmer syntax](https://sr.ht/~kerrick/ratatui_ruby/#chapter-4-the-syntax) (Planned) • **Framework:** [Omakase framework](https://git.sr.ht/~kerrick/ratatui_ruby-framework) (Planned) • **UI:** [Polished widgets](https://git.sr.ht/~kerrick/ratatui_ruby-ui) (Planned) • **UI Pro:** [More polished widgets](https://sr.ht/~kerrick/ratatui_ruby#chapter-6-licensing) (Planned)

### For App Developers

**Get Started:** [Quickstart](https://github.com/setdef/RatatuiRuby/blob/stable/doc/getting_started/quickstart.md) • [Examples](https://github.com/setdef/RatatuiRuby/blob/stable/examples/app_all_events/README.md) ⸺ **Stay Informed:** [Announcements](https://forum.setdef.com/tags/c/ratatui-ruby/6/announcement) • [FAQ](https://man.sr.ht/~kerrick/ratatui_ruby/troubleshooting.md) ⸺ **Reach Out:** [Forum](https://forum.setdef.com/c/ratatui-ruby/6) • [Bug Tracker](https://forum.setdef.com/tags/c/ratatui-ruby/6/bug)

### For Contributors

**Get Started:** [Contributing Guide](https://man.sr.ht/~kerrick/ratatui_ruby/contributing.md) • [Code of Conduct](https://man.sr.ht/~kerrick/ratatui_ruby/code_of_conduct.md) ⸺ **Stay Informed:** [Announcements](https://forum.setdef.com/tags/c/ratatui-ruby/6/announcement) • [Project History](https://man.sr.ht/~kerrick/ratatui_ruby/history/index.md) ⸺ **Reach Out:** [Issues](https://github.com/setdef/ratatui_ruby-devtools/issues)

---

## Installation

Add this line to your application's Gemfile:

<!-- SPDX-SnippetBegin -->
<!--
  SPDX-SnippetCopyrightText: 2026 Kerrick Long
  SPDX-License-Identifier: MIT-0
-->
```ruby
group :development do
  gem "ratatui_ruby-devtools"
end
```
<!-- SPDX-SnippetEnd -->

And then execute:

<!-- SPDX-SnippetBegin -->
<!--
  SPDX-SnippetCopyrightText: 2026 Kerrick Long
  SPDX-License-Identifier: MIT-0
-->
```bash
bundle install
```
<!-- SPDX-SnippetEnd -->


## Usage

In your `Rakefile`:

<!-- SPDX-SnippetBegin -->
<!--
  SPDX-SnippetCopyrightText: 2026 Kerrick Long
  SPDX-License-Identifier: MIT-0
-->
```ruby
require "bundler/gem_tasks"
require "ratatui_ruby/devtools"

RatatuiRuby::Devtools.install!

task default: %i[lint]
```
<!-- SPDX-SnippetEnd -->

This imports all devtools rake tasks into your project.


## Provided Rake Tasks

### Linting

| Task | Description |
|------|-------------|
| `rake lint` | Run all lint tasks |
| `rake lint:fix` | Auto-fix all linting issues |
| `rake rubocop` | Run RuboCop |
| `rake rubycritic` | Run RubyCritic |
| `rake lint:lockfile_ruby` | Check that every locked gem installs on the oldest supported Ruby |
| `rake doc:suggest` | Suggest documentation improvements |
| `rake doc:check_links` | Check for broken links in RDoc and Markdown files |

### License Enforcement

| Task | Description |
|------|-------------|
| `rake license:all` | Run all license tasks |
| `rake license:headers:all` | Ensure all files have SPDX headers |
| `rake license:new` | Apply license headers to changed files only |
| `rake reuse:lint` | Check REUSE/SPDX compliance |
| `rake reuse:fix` | Add missing SPDX headers |

### Version Bumping

| Task | Description |
|------|-------------|
| `rake bump:major` | Bump major version |
| `rake bump:minor` | Bump minor version |
| `rake bump:patch` | Bump patch version |
| `rake 'bump:minor[rc]'` | Bump to a prerelease, such as `1.2.0-rc.1` |
| `rake bump:exact[0.1.0]` | Set exact version |

Every bump commits the release for you and refuses to start on the wrong branch or with uncommitted changes.

Before 1.0, your gem is in initial development, and its API can change in any release. Those releases are still normal versions, so `gem install` and Bundler find them. A new gem starts at `0.0.0`, so its first `bump:patch` or `bump:minor` releases `0.0.1` or `0.1.0`.

A prerelease is different. `1.2.0-beta.1` is a candidate for `1.2.0`, and users get it only with `gem install --pre` or a requirement that names a prerelease. A bump makes one only when you give it a label: `rake 'bump:minor[beta]'` takes `1.1.3` to `1.2.0-beta.1`, and again to `1.2.0-beta.2`. Another label starts again at `.1`, so `rake 'bump:minor[rc]'` then releases `1.2.0-rc.1`. A label has to sort after the one you're on, because SemVer compares labels as text: `rc` follows `beta`, but `beta` doesn't follow `dev`. A bump without a label ships the candidate, so `bump:minor` or `bump:patch` takes `1.2.0-rc.1` to `1.2.0`. Candidates release on trunk.

Before 1.0, every release comes from trunk. Run any bump there.

From 1.0 on, each minor version gets a release branch, so its users can take patch releases without the next minor's changes. A bump that releases a new minor or major version, one ending in `.0`, runs on trunk: it creates `release/X.Y`, commits the release there, imports the release into trunk, and commits that too. A bump that releases a patch runs on the release branch it fixes. The version decides, not the task: finishing `1.2.0-beta.1` releases `1.2.0`, so even `bump:patch` runs on trunk and creates `release/1.2`. The first release of 1.0 starts this workflow.


## Executables

### `bin/agent_rake`

An AI-friendly wrapper for `bundle exec rake` that captures all output and only shows failure summaries.

<!-- SPDX-SnippetBegin -->
<!--
  SPDX-SnippetCopyrightText: 2026 Kerrick Long
  SPDX-License-Identifier: MIT-0
-->
```bash
bin/agent_rake           # Run default task
bin/agent_rake test      # Run specific task
```
<!-- SPDX-SnippetEnd -->

### `bin/consolidate_md`

Merge multiple markdown files into one, adjusting heading levels.

### `bin/hbs`

Handlebars templating utility.


## Templates

Devtools includes templates for scaffolding new ecosystem gems:

| Template | Purpose |
|----------|---------|
| `AGENTS.md.erb` | AI agent instructions |
| `.pre-commit-config.yaml` | Pre-commit hooks |
| `Rakefile.erb` | Standard Rakefile |
| `gemspec.erb` | Standard gemspec |
| `bin/setup.erb` | Setup script |
| `mise.toml.erb` | Toolchain versions |
| `REUSE.toml.erb` | License annotations |
| `.gitignore.erb` | Git ignores |
| `.rubocop.yml.erb` | RuboCop config |

Access templates via:

<!-- SPDX-SnippetBegin -->
<!--
  SPDX-SnippetCopyrightText: 2026 Kerrick Long
  SPDX-License-Identifier: MIT-0
-->
```ruby
RatatuiRuby::Devtools.templates_path
# => "/path/to/devtools/templates"
```
<!-- SPDX-SnippetEnd -->


## Configuration

Tasks find your gemspec, your gem's name, and its version file from your gem's files. Pass any of them when you install the tasks, if your gem keeps them elsewhere:

<!-- SPDX-SnippetBegin -->
<!--
  SPDX-SnippetCopyrightText: 2026 Kerrick Long
  SPDX-License-Identifier: MIT-0
-->
```ruby
RatatuiRuby::Devtools.install_gem_tasks!(
  gem_name: "my_gem",
  version_file: "lib/my_gem/version.rb"
)
```
<!-- SPDX-SnippetEnd -->

The license tasks give the code apps link, from your gemspec's `require_paths` and `extensions`, the license in your gemspec. Everything else, such as tests, tasks, and type signatures, gets AGPL-3.0-or-later. Examples that app developers copy whole are snippets grown large, so you can give them MIT-0 like the snippets in your docs. A commercial gem can license its other code differently:

<!-- SPDX-SnippetBegin -->
<!--
  SPDX-SnippetCopyrightText: 2026 Kerrick Long
  SPDX-License-Identifier: MIT-0
-->
```ruby
RatatuiRuby::Devtools.install_gem_tasks!(
  snippet_paths: %w[examples/widget_ examples/verify_],
  non_runtime_license: "LicenseRef-Commercial"
)
```
<!-- SPDX-SnippetEnd -->

Each header names the commit authors whose lines remain in the file, with the last year each touched them. Copyright protects only original expression, so a change too small to hold it, such as a corrected path, needs no notice. List its commit in `.git-blame-ignore-revs`, and the license tasks blame its lines on the commits before it, as GitHub's blame view does:

<!-- SPDX-SnippetBegin -->
<!--
  SPDX-SnippetCopyrightText: 2026 Kerrick Long
  SPDX-License-Identifier: MIT-0
-->
```text
# Corrects the relative paths to examples/
0123456789abcdef0123456789abcdef01234567
```
<!-- SPDX-SnippetEnd -->

`rake reuse:fix` gives Ruby, RBS, Rust, and Markdown files the same headers the license tasks write. Environment variables set what it writes for other files:

| Variable | Default |
|----------|---------|
| `REUSE_COPYRIGHT` | Your git `user.name` and `user.email` |
| `REUSE_CODE_LICENSE` | The license the license tasks would choose |
| `REUSE_DOC_LICENSE` | `CC-BY-SA-4.0` |


## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/setdef/ratatui_ruby-devtools/issues). This project is intended to be a safe, productive collaboration, and contributors are expected to adhere to the [Code of Conduct](https://man.sr.ht/~kerrick/ratatui_ruby/code_of_conduct.md).

Want to help develop **ratatui_ruby-devtools**? Check out the [contribution guide on the wiki](https://man.sr.ht/~kerrick/ratatui_ruby/contributing.md).


## Copyright & License

**ratatui_ruby-devtools** is copyright 2026, Kerrick Long.

The gem is [AGPL-3.0-or-later](./LICENSES/AGPL-3.0-or-later.txt): you may use it freely, but you must share changes you make. Documentation is [CC-BY-SA-4.0](./LICENSES/CC-BY-SA-4.0.txt). Code snippets in documentation are [MIT-0](./LICENSES/MIT-0.txt) (no attribution required).

This program was created with significant assistance from multiple LLMs. The process was human-controlled through creative prompts, with human contributions to each commit. See commit footers for model attribution. [declare-ai.org](https://declare-ai.org/1.0.0/creative.html)
