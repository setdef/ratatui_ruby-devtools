# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rake/tasklib"

require_relative "bump/repository"
require_relative "license/reuse_tool"
require_relative "license/unlicensed_files"

# The tasks that check and fix REUSE compliance.
class ReuseTasks < Rake::TaskLib # :nodoc:
  def initialize(licensing)
    super()
    @licensing = licensing
    define
  end

  private def define
    namespace :reuse do
      desc "Run the REUSE Tool to confirm REUSE compliance"
      task :lint do
        sh "reuse lint"
      end

      desc "Add SPDX headers to files missing them (per AGENTS.md standards)"
      task :fix do
        puts "Checking for files missing REUSE headers..."
        overrides = ENV.slice("REUSE_COPYRIGHT", "REUSE_CODE_LICENSE", "REUSE_DOC_LICENSE")
        UnlicensedFiles.new(ReuseTool.new, Repository.new, overrides, @licensing).license.each { |message| puts message }
      end
    end

    task(:reuse) { Rake::Task["reuse:lint"].invoke }
  end
end
