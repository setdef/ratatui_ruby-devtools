# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rdoc"

# The code blocks of an RDoc document, wherever they sit, as RDoc's own
# table of contents collects its headings.
class RdocExamples < RDoc::Markup::Formatter # :nodoc:
  def initialize
    super(RDoc::Options.new)
  end

  def start_accepting
    @examples = []
  end

  def end_accepting
    @examples
  end

  def accept_verbatim(verbatim)
    @examples << verbatim
  end

  def ignore(*)
  end

  alias accept_block_quote ignore
  alias accept_raw ignore
  alias accept_rule ignore
  alias accept_blank_line ignore
  alias accept_hard_break ignore
  alias accept_heading ignore
  alias accept_paragraph ignore
  alias accept_indented_paragraph ignore
  alias accept_list_start ignore
  alias accept_list_end ignore
  alias accept_list_item_start ignore
  alias accept_list_item_end ignore
  alias accept_table ignore
end
