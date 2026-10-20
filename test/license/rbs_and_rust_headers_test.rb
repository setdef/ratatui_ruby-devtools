# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/license/licensed_file"
require "ratatui_ruby/devtools/tasks/license/rbs_header_syntax"
require "ratatui_ruby/devtools/tasks/license/rust_header_syntax"

# REUSE-IgnoreStart
class RbsAndRustHeadersTest < DevtoolsTest
  KERRICK = "Kerrick Long <me@kerricklong.com>"
  RBS_HEADER = "#--\n# SPDX-FileCopyrightText: 2024 #{KERRICK}\n# SPDX-License-Identifier: AGPL-3.0-or-later\n#++\n\n".freeze
  RUST_HEADER = "// SPDX-FileCopyrightText: 2024 #{KERRICK}\n// SPDX-License-Identifier: LGPL-3.0-or-later\n\n".freeze

  def test_adds_an_rbs_header_without_a_magic_comment
    files = in_gem("sig/fixture/a.rbs" => "\nclass A\nend\n") { annotate(RbsHeaderSyntax) }

    assert_equal "#{RBS_HEADER}class A\nend\n", files["sig/fixture/a.rbs"]
  end

  def test_drops_the_magic_comment_from_an_rbs_header_it_replaces
    text = "# frozen_string_literal: true\n\n#--\n# SPDX-FileCopyrightText: 2024 #{KERRICK}\n" \
      "# SPDX-License-Identifier: MIT\n#++\n\nclass A\nend\n"
    files = in_gem("sig/fixture/a.rbs" => text) { annotate(RbsHeaderSyntax) }

    assert_equal "#{RBS_HEADER}class A\nend\n", files["sig/fixture/a.rbs"]
  end

  def test_leaves_a_correct_rbs_header_alone
    text = "# SPDX-FileCopyrightText: 2024 #{KERRICK}\n# SPDX-License-Identifier: AGPL-3.0-or-later\n\n# A class.\nclass A\nend\n"
    messages = nil
    files = in_gem("sig/fixture/a.rbs" => text) { messages = annotate(RbsHeaderSyntax) }

    assert_empty messages
    assert_equal text, files["sig/fixture/a.rbs"]
  end

  def test_adds_a_rust_header
    files = in_gem("ext/fixture/src/lib.rs" => "fn main() {}\n") { annotate(RustHeaderSyntax) }

    assert_equal "#{RUST_HEADER}fn main() {}\n", files["ext/fixture/src/lib.rs"]
  end

  def test_keeps_a_comment_after_a_rust_header
    text = "// SPDX-FileCopyrightText: 2024 #{KERRICK}\n// SPDX-License-Identifier: MIT\n// A doc comment\n\nfn b() {}\n"
    files = in_gem("ext/fixture/src/b.rs" => text) { annotate(RustHeaderSyntax) }

    assert_equal "#{RUST_HEADER}// A doc comment\n\nfn b() {}\n", files["ext/fixture/src/b.rs"]
  end

  def test_replaces_a_rust_header_through_its_last_tag
    {
      "no_license" => "// SPDX-FileCopyrightText: 2024 Jane Doe <jane@example.com>\n" \
        "// SPDX-FileCopyrightText: 2024 #{KERRICK}\n\nfn d() {}\n",
      "license_first" => "// SPDX-License-Identifier: MIT\n// SPDX-FileCopyrightText: 2024 #{KERRICK}\n\nfn d() {}\n",
      "gap" => "// SPDX-FileCopyrightText: 2024 #{KERRICK}\n\n// SPDX-License-Identifier: MIT\n\nfn d() {}\n",
    }.each do |name, text|
      path = "ext/fixture/src/#{name}.rs"
      files = in_gem(path => text) { annotate(RustHeaderSyntax) }

      assert_equal 1, files[path].scan("SPDX-FileCopyrightText: 2024 #{KERRICK}").size, name
      assert_equal 1, files[path].scan("SPDX-License-Identifier").size, name
      assert files[path].end_with?("\nfn d() {}\n"), name
    end
  end

  # Commits +files+ in 2024 to an LGPL gem with an extension, runs the block
  # there, and returns what the files hold afterwards.
  private def in_gem(files)
    FixtureRepository.open do |repository|
      repository.gemspec(license: "LGPL-3.0-or-later", extensions: ["ext/fixture/extconf.rb"])
      files.each { |path, text| repository.write(path, text) }
      repository.commit(date: "2024-06-01")
      yield
      files.keys.to_h { |path| [path, repository.read(path)] }
    end
  end

  private def annotate(syntax)
    LicensedFile.tracked([], syntax.new).flat_map(&:annotate)
  end
end
# REUSE-IgnoreEnd
