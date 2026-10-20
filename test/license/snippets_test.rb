# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "test_helper"
require "ratatui_ruby/devtools/tasks/license/markdown_snippet_syntax"
require "ratatui_ruby/devtools/tasks/license/rdoc_snippet_syntax"
require "ratatui_ruby/devtools/tasks/license/snippet_file"

# REUSE-IgnoreStart
class SnippetsTest < DevtoolsTest
  KERRICK = "Kerrick Long <me@kerricklong.com>"
  JANE = FixtureRepository::Person.new(name: "Jane", email: "jane@example.com")
  BOB = FixtureRepository::Person.new(name: "Bob", email: "bob@example.com")
  FENCE = "```"

  def test_wraps_a_markdown_code_block
    FixtureRepository.open do |repository|
      repository.write("doc/plain.md", "# Plain\n\n#{FENCE}ruby\nputs 1\n#{FENCE}\n\nAfter.\n")
      repository.commit(date: "2024-06-01")

      assert_equal ["Updated: doc/plain.md (1 code block(s))"], annotate_markdown
      assert_equal "# Plain\n\n#{wrapper("2024 #{KERRICK}", "#{FENCE}ruby\nputs 1\n#{FENCE}\n")}\nAfter.\n",
        repository.read("doc/plain.md")
    end
  end

  def test_wraps_a_four_backtick_block_whole
    inner = "````markdown\n#{FENCE}ruby\ninner\n#{FENCE}\n````\n"
    FixtureRepository.open do |repository|
      repository.write("doc/four.md", "# Four\n\n#{inner}")
      repository.commit(date: "2024-06-01")
      annotate_markdown

      assert_equal "# Four\n\n#{wrapper("2024 #{KERRICK}", inner)}", repository.read("doc/four.md")
    end
  end

  def test_wraps_sync_markers_with_the_block_they_hold
    synced = "<!-- SYNC:START:examples/a.rb -->\n#{FENCE}ruby\nputs 5\n#{FENCE}\n<!-- SYNC:END -->\n"
    FixtureRepository.open do |repository|
      repository.write("doc/sync.md", "# Sync\n\n#{synced}")
      repository.commit(date: "2024-06-01")
      annotate_markdown

      assert_equal "# Sync\n\n#{wrapper("2024 #{KERRICK}", synced)}", repository.read("doc/sync.md")
    end
  end

  def test_leaves_an_unclosed_block_and_an_unended_wrapper_alone
    unclosed = "# Unclosed\n\n#{FENCE}ruby\nputs 6\n"
    unended = "# No end\n\n<!-- SPDX-SnippetBegin -->\n#{FENCE}ruby\nputs 8\n#{FENCE}\n"
    FixtureRepository.open do |repository|
      repository.write("doc/unclosed.md", unclosed)
      repository.write("doc/no_end.md", unended)
      repository.commit(date: "2024-06-01")

      assert_empty annotate_markdown
      assert_equal unclosed, repository.read("doc/unclosed.md")
      assert_equal unended, repository.read("doc/no_end.md")
    end
  end

  def test_converts_an_old_snippet_tag_and_renews_its_year
    FixtureRepository.open do |repository|
      repository.write("doc/ours.md", "# Ours\n\n#{old_wrapper('2020 Kerrick Long', "#{FENCE}ruby\nputs 2\n#{FENCE}\n")}")
      repository.commit(date: "2024-06-01")

      assert_equal ["  Updated Kerrick's copyright year: 2020 -> 2024", "Updated: doc/ours.md"], annotate_markdown
      assert_equal "# Ours\n\n#{wrapper('2024 Kerrick Long', "#{FENCE}ruby\nputs 2\n#{FENCE}\n")}",
        repository.read("doc/ours.md")
    end
  end

  def test_credits_an_uncommitted_snippet_to_the_runner_this_year
    FixtureRepository.open do |repository|
      repository.write("doc/later.md", "# Later\n\nProse.\n")
      repository.commit(date: "2024-06-01")
      repository.write("doc/later.md", "# Later\n\nProse.\n\n#{FENCE}ruby\nputs 9\n#{FENCE}\n")
      annotate_markdown

      assert_equal "# Later\n\nProse.\n\n#{wrapper("#{this_year} #{KERRICK}", "#{FENCE}ruby\nputs 9\n#{FENCE}\n")}",
        repository.read("doc/later.md")
    end
  end

  def test_dates_a_snippet_by_its_own_lines
    old = "# Doc\n\n#{old_wrapper('2020 Jane Doe', "#{FENCE}ruby\nold\n#{FENCE}\n")}\nProse.\n"
    FixtureRepository.open do |repository|
      repository.write("doc.md", old)
      repository.commit(date: "2020-06-01", author: FixtureRepository::Person.new(name: "Jane Doe", email: "jane@example.com"))
      repository.write("doc.md", "#{old}\nMore prose.\n\n#{FENCE}ruby\nnew\n#{FENCE}\n")
      repository.commit(date: "2024-06-01")
      annotate_markdown
      text = repository.read("doc.md")

      assert_includes text, wrapper("2020 Jane Doe", "#{FENCE}ruby\nold\n#{FENCE}\n")
      assert_includes text, wrapper("2024 #{KERRICK}", "#{FENCE}ruby\nnew\n#{FENCE}\n")
    end
  end

  def test_credits_whoever_edits_a_wrapped_snippet_once
    FixtureRepository.open do |repository|
      repository.write("doc.md", "# Doc\n\n#{jane_snippet('kept')}\n#{jane_snippet('jane')}")
      repository.commit(date: "2021-06-01", author: JANE)
      repository.write("doc.md", repository.read("doc.md").sub("jane\n", "bob_edited\n"))
      repository.commit(date: "2024-06-01", author: BOB)

      assert_equal ["  Adding Bob's copyright", "Updated: doc.md"], annotate_markdown
      assert_empty annotate_markdown
      assert_includes repository.read("doc.md"), jane_snippet("kept")
      assert_includes repository.read("doc.md"),
        "  SPDX-SnippetCopyrightText: 2021 Jane <jane@example.com>\n  SPDX-SnippetCopyrightText: 2024 Bob <bob@example.com>\n"
    end
  end

  def test_wraps_a_multi_line_rdoc_example
    FixtureRepository.open do |repository|
      repository.write("lib/thing.rb", "# Makes things.\n#\n#   Thing.new\n#   Thing.call\nclass Thing; end\n")
      repository.commit(date: "2024-06-01")

      assert_equal ["Updated: lib/thing.rb (1 code block(s))"], annotate_rdoc
      assert_equal "# Makes things.\n#\n#{rdoc_wrapper("2024 #{KERRICK}", "#   Thing.new\n#   Thing.call\n")}class Thing; end\n",
        repository.read("lib/thing.rb")
    end
  end

  def test_wraps_each_indented_rdoc_example
    text = "class Two\n  # A.\n  #\n  #   a = 1\n  #   a + 1\n  #\n  # B.\n  #\n  #   b = 2\n  #   b * 2\n  def two; end\nend\n"
    FixtureRepository.open do |repository|
      repository.write("lib/two.rb", text)
      repository.commit(date: "2024-06-01")

      assert_equal ["Updated: lib/two.rb (2 code block(s))"], annotate_rdoc
      assert_includes repository.read("lib/two.rb"),
        rdoc_wrapper("2024 #{KERRICK}", "  #   b = 2\n  #   b * 2\n", indent: "  ")
    end
  end

  def test_wraps_a_one_line_rdoc_example
    FixtureRepository.open do |repository|
      repository.write("lib/one.rb", "# Returns the margin.\n#\n#   layout.margin # => 2\nclass One; end\n")
      repository.commit(date: "2024-06-01")
      annotate_rdoc

      assert_equal "# Returns the margin.\n#\n#{rdoc_wrapper("2024 #{KERRICK}", "#   layout.margin # => 2\n")}class One; end\n",
        repository.read("lib/one.rb")
    end
  end

  def test_wraps_an_rdoc_example_that_follows_a_line_of_text
    FixtureRepository.open do |repository|
      repository.write("lib/update.rb", "# Receive in Update:\n#   in { type: :loaded }\nclass Update; end\n")
      repository.commit(date: "2024-06-01")
      annotate_rdoc

      assert_equal "# Receive in Update:\n#{rdoc_wrapper("2024 #{KERRICK}", "#   in { type: :loaded }\n")}class Update; end\n",
        repository.read("lib/update.rb")
    end
  end

  def test_leaves_a_list_items_indented_lines_alone
    text = "# Splits an area.\n#\n# [area]\n#   The area to split.\n#   Can be a Rect.\n# [kind]\n#   Event kind.\nclass Split; end\n"
    FixtureRepository.open do |repository|
      repository.write("lib/split.rb", text)
      repository.commit(date: "2024-06-01")

      assert_empty annotate_rdoc
      assert_equal text, repository.read("lib/split.rb")
    end
  end

  def test_leaves_meta_comments_and_call_seqs_alone_but_wraps_their_examples
    text = "class Text\n  ##\n  # :attr_reader: x\n  # X coordinate.\n\n  ##\n  # :method: width\n  # :call-seq:\n" \
      "  #   width(string) -> Integer\n  #\n  # Measures.\n  #\n  #   Text.width(\"hi\") # => 2\nend\n"
    FixtureRepository.open do |repository|
      repository.write("lib/text.rb", text)
      repository.commit(date: "2024-06-01")

      assert_equal ["Updated: lib/text.rb (1 code block(s))"], annotate_rdoc
      assert_includes repository.read("lib/text.rb"),
        "  # :call-seq:\n  #   width(string) -> Integer\n  #\n  # Measures.\n  #\n" \
          "#{rdoc_wrapper("2024 #{KERRICK}", "  #   Text.width(\"hi\") # => 2\n", indent: '  ')}end\n"
    end
  end

  def test_keeps_blank_lines_after_an_rdoc_example_outside_its_wrapper
    FixtureRepository.open do |repository|
      repository.write("lib/trail.rb", "# Trailing.\n#\n#   Trail.new\n#\n#\nclass Trail; end\n")
      repository.commit(date: "2024-06-01")
      annotate_rdoc

      assert_equal "# Trailing.\n#\n#{rdoc_wrapper("2024 #{KERRICK}", "#   Trail.new\n")}#\n#\nclass Trail; end\n",
        repository.read("lib/trail.rb")
    end
  end

  def test_moves_blank_lines_out_of_an_existing_wrapper
    wrapped = rdoc_wrapper("2024 #{KERRICK}", "#   Trail.new\n#\n")
    FixtureRepository.open do |repository|
      repository.write("lib/trail.rb", "# Trailing.\n#\n#{wrapped}class Trail; end\n")
      repository.commit(date: "2024-06-01")

      assert_equal ["Updated: lib/trail.rb"], annotate_rdoc
      assert_equal "# Trailing.\n#\n#{rdoc_wrapper("2024 #{KERRICK}", "#   Trail.new\n")}#\nclass Trail; end\n",
        repository.read("lib/trail.rb")
    end
  end

  def test_unwraps_a_list_items_text
    item = "# [area]\n#   A Rect specifying where to render.\n"
    wrapped = "# [area]\n#{rdoc_wrapper('2025 Kerrick Long', "#   A Rect specifying where to render.\n")}"
    FixtureRepository.open do |repository|
      repository.write("lib/frame.rb", "# Renders a widget.\n#\n#{wrapped}def render; end\n")
      repository.commit(date: "2024-06-01")

      assert_equal ["Updated: lib/frame.rb"], annotate_rdoc
      assert_equal "# Renders a widget.\n#\n#{item}def render; end\n", repository.read("lib/frame.rb")
    end
  end

  def test_credits_whoever_edits_a_wrapped_rdoc_example_once
    FixtureRepository.open do |repository|
      repository.write("lib/a.rb", "# A.\n#\n#{jane_rdoc('A.kept')}class A; end\n\n# B.\n#\n#{jane_rdoc('B.jane')}class B; end\n")
      repository.commit(date: "2021-06-01", author: JANE)
      repository.write("lib/a.rb", repository.read("lib/a.rb").sub("B.jane", "B.bob_edited"))
      repository.commit(date: "2024-06-01", author: BOB)

      assert_equal ["  Adding Bob's copyright", "Updated: lib/a.rb"], annotate_rdoc
      assert_empty annotate_rdoc
      assert_includes repository.read("lib/a.rb"), jane_rdoc("A.kept")
    end
  end

  private def annotate_markdown
    SnippetFile.tracked([], MarkdownSnippetSyntax.new).flat_map(&:annotate)
  end

  private def annotate_rdoc
    SnippetFile.tracked(["lib"], RdocSnippetSyntax.new).flat_map(&:annotate)
  end

  private def wrapper(copyright, code)
    "<!-- SPDX-SnippetBegin -->\n<!--\n  SPDX-SnippetCopyrightText: #{copyright}\n  SPDX-License-Identifier: MIT-0\n-->\n" \
      "#{code}<!-- SPDX-SnippetEnd -->\n"
  end

  private def old_wrapper(copyright, code)
    wrapper(copyright, code).sub("SPDX-SnippetCopyrightText", "SPDX-FileCopyrightText")
  end

  private def jane_snippet(body)
    wrapper("2021 Jane <jane@example.com>", "#{FENCE}ruby\n#{body}\n#{FENCE}\n")
  end

  private def rdoc_wrapper(copyright, code, indent: "")
    "#{indent}#--\n#{indent}# SPDX-SnippetBegin\n#{indent}# SPDX-SnippetCopyrightText: #{copyright}\n" \
      "#{indent}# SPDX-License-Identifier: MIT-0\n#{indent}#++\n#{code}#{indent}#--\n#{indent}# SPDX-SnippetEnd\n#{indent}#++\n"
  end

  private def jane_rdoc(body)
    rdoc_wrapper("2021 Jane <jane@example.com>", "#   #{body}\n#   more\n")
  end
end
# REUSE-IgnoreEnd
