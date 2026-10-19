# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require_relative "licensed_file"
require_relative "licensing"
require_relative "markdown_header_syntax"
require_relative "rbs_header_syntax"
require_relative "reuse_annotated_file"
require_relative "ruby_header_syntax"
require_relative "rust_header_syntax"
require_relative "unknown_file"

# The files the REUSE Tool finds without headers. The license tasks know each
# language's header and who to credit, so the tool annotates only the rest.
class UnlicensedFiles # :nodoc:
  SYNTAXES = [MarkdownHeaderSyntax, RubyHeaderSyntax, RbsHeaderSyntax, RustHeaderSyntax].freeze
  CODE_EXTENSIONS = %w[rb rs rake gemspec rbs toml yml yaml json lock].freeze
  DOC_EXTENSIONS = %w[md txt].freeze
  DOC_LICENSE = "CC-BY-SA-4.0"

  def initialize(tool, repository, overrides)
    @tool = tool
    @repository = repository
    @overrides = overrides
    @syntaxes = SYNTAXES.map(&:new)
  end

  # Licenses what the tool found and says what it did.
  def license
    paths = @tool.unlicensed_paths
    return ["All files have REUSE headers!"] if paths.empty?

    paths.flat_map { |path| file_at(path).annotate.map { |message| "  #{message}" } }
  end

  private def file_at(path)
    syntax = @syntaxes.find { |candidate| candidate.covers?(path) }
    return LicensedFile.new(path:, syntax:, author:) if syntax

    license = license_for(path)
    return UnknownFile.new(path:) unless license

    ReuseAnnotatedFile.new(path:, license:, copyright:, tool: @tool)
  end

  private def license_for(path)
    case File.extname(path).delete_prefix(".")
    when *CODE_EXTENSIONS then @overrides.fetch("REUSE_CODE_LICENSE") { licensing.license_for(path) }
    when *DOC_EXTENSIONS then @overrides.fetch("REUSE_DOC_LICENSE", DOC_LICENSE)
    end
  end

  private def copyright
    @overrides.fetch("REUSE_COPYRIGHT") { author.to_s }
  end

  private def author
    @author ||= @repository.author
  end

  private def licensing
    @licensing ||= Licensing.current
  end
end
