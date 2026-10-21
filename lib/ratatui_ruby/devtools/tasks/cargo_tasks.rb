# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "rake/tasklib"

# Cargo tasks for Rust extensions.
# Only registered if ext/ directory exists.
class CargoTasks < Rake::TaskLib # :nodoc:
  def initialize
    super
    define
  end

  private def define
    if Dir.exist?("ext")
      namespace :cargo do
        desc "Run cargo fmt"
        task :fmt do
          ext_dirs = Dir.glob("ext/*").select { |d| File.directory?(d) && File.exist?("#{d}/Cargo.toml") }
          ext_dirs.each do |dir|
            sh "cd #{dir} && cargo fmt --all -- --check"
          end
        end

        desc "Run cargo clippy"
        task :clippy do
          ext_dirs = Dir.glob("ext/*").select { |d| File.directory?(d) && File.exist?("#{d}/Cargo.toml") }
          ext_dirs.each do |dir|
            sh "cd #{dir} && cargo clippy -- -D warnings"
          end
        end

        desc "Run cargo test"
        task :test do
          ext_dirs = Dir.glob("ext/*").select { |d| File.directory?(d) && File.exist?("#{d}/Cargo.toml") }
          ext_dirs.each do |dir|
            sh "cd #{dir} && cargo test"
          end
        end

        namespace :fix do
          desc "Auto-fix Clippy warnings (most aggressive)"
          task :clippy do
            ext_dirs = Dir.glob("ext/*").select { |d| File.directory?(d) && File.exist?("#{d}/Cargo.toml") }
            ext_dirs.each do |dir|
              sh "cd #{dir} && cargo clippy --fix --allow-dirty --allow-staged"
            end
          end
        end
      end
    end
  end
end
