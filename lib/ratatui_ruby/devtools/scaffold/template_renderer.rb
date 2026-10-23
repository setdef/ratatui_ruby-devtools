# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 Kerrick Long <me@kerricklong.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#++

require "erb"
require "fileutils"

# Renders ERB templates into the target directory.
#
# Templates use ERB to inject gem-specific values. This class handles the
# rendering and file creation with proper directory structure.
class TemplateRenderer
  # Creates a new renderer with config and paths.
  #
  # [config] The ScaffoldConfig with gem parameters.
  # [templates_dir] Path to the ERB templates.
  # [output_dir] Path where rendered files are written.
  # [update_mode] Whether to ask before overwriting a file that differs.
  # [input] Where the answers to those questions come from.
  def initialize(config, templates_dir, output_dir, update_mode: false, input: $stdin)
    @config = config
    @templates_dir = templates_dir
    @output_dir = output_dir
    @update_mode = update_mode
    @input = input
  end

  # Renders all templates into the output directory.
  def render_all
    FileUtils.mkdir_p(@output_dir)

    render_template(".gitignore.erb", ".gitignore")
    render_template(".pre-commit-config.yaml.erb", ".pre-commit-config.yaml")
    render_template(".rubocop.yml.erb", ".rubocop.yml")
    render_template("AGENTS.md.erb", "AGENTS.md")
    render_template("CHANGELOG.md.erb", "CHANGELOG.md") unless @update_mode
    render_template("CONTRIBUTING.md.erb", "CONTRIBUTING.md")
    render_template("CODE_OF_CONDUCT.md.erb", "CODE_OF_CONDUCT.md")
    render_template("Gemfile.erb", "Gemfile")
    render_template("README.md.erb", "README.md")
    render_template("REUSE.toml.erb", "REUSE.toml")
    render_template("Rakefile.erb", "Rakefile")
    render_template("gemspec.erb", "#{@config.gem_name}.gemspec")
    render_template("mise.toml.erb", "mise.toml")

    # bin/ scripts
    render_template("bin/setup.erb", "bin/setup", executable: true)
    render_template("bin/setup.ps1.erb", "bin/setup.ps1")
    render_template("bin/console.erb", "bin/console", executable: true)

    # GitHub Actions CI workflow
    render_template(".github/workflows/ci.yml.erb", ".github/workflows/ci.yml")

    # GitHub Actions build-gems workflow (Rust only)
    render_template(".github/workflows/build-gems.yml.erb", ".github/workflows/build-gems.yml") if @config.has_rust

    # task resources
    copy_task_resources

    # doc files (RDoc styling)
    copy_doc_files

    # lib/ structure
    create_lib_structure

    # Rust extension (if enabled)
    create_rust_extension if @config.has_rust

    puts "Scaffolded #{@config.gem_name} in #{@output_dir}"
  end

  private def render_template(template_name, output_name, executable: false)
    template_path = File.join(@templates_dir, template_name)
    output_path = File.join(@output_dir, output_name)

    FileUtils.mkdir_p(File.dirname(output_path))

    unless File.exist?(template_path)
      warn "  WARNING: Template not found: #{template_name}"
      return
    end

    content = if template_name.end_with?(".erb")
      ERB.new(File.read(template_path), trim_mode: "-").result(binding_for_config)
    else
      File.read(template_path)
    end

    if @update_mode && File.exist?(output_path)
      existing = File.read(output_path)
      if existing == content
        puts "  Unchanged #{output_name}"
        return
      end
      puts "  Conflict #{output_name}"
      show_diff(output_path, content)
      print "  Overwrite #{output_name}? [y/N] "
      answer = @input.gets&.strip
      unless answer&.match?(/^[Yy]/)
        puts "  Skipped #{output_name}"
        return
      end
    end

    File.write(output_path, content)
    FileUtils.chmod(0o755, output_path) if executable
    puts "  Created #{output_name}"
  end

  private def show_diff(existing_path, new_content)
    require "tempfile"
    Tempfile.create(["scaffold", File.extname(existing_path)]) do |tmp|
      tmp.write(new_content)
      tmp.flush
      system("git", "--no-pager", "diff", "--no-index", "--color", existing_path, tmp.path)
    end
  end

  private def copy_task_resources
    # Render example_viewer.html.erb to tasks/
    render_template("tasks/example_viewer.html.erb", "tasks/example_viewer.html.erb")

    # Create exe/.gitkeep
    exe_dir = File.join(@output_dir, "exe")
    FileUtils.mkdir_p(exe_dir)
    gitkeep = File.join(exe_dir, ".gitkeep")
    FileUtils.touch(gitkeep)
    puts "  Created exe/.gitkeep"
  end

  private def copy_doc_files
    doc_dir = File.join(@output_dir, "doc")
    FileUtils.mkdir_p(doc_dir)
    FileUtils.mkdir_p(File.join(doc_dir, "getting_started"))
    FileUtils.mkdir_p(File.join(doc_dir, "concepts"))
    FileUtils.mkdir_p(File.join(doc_dir, "images"))

    # Render custom.css (now an ERB template)
    render_template("doc/custom.css.erb", "doc/custom.css")

    # Create images/.gitkeep
    FileUtils.touch(File.join(doc_dir, "images", ".gitkeep"))
    puts "  Created doc/images/.gitkeep"

    # Render doc templates
    render_template("doc/index.md.erb", "doc/index.md")
    render_template("doc/getting_started/quickstart.md.erb", "doc/getting_started/quickstart.md")
    render_template("doc/concepts/application_architecture.md.erb", "doc/concepts/application_architecture.md")
    render_template("doc/concepts/application_testing.md.erb", "doc/concepts/application_testing.md")
  end

  private def create_lib_structure
    lib_path = File.join(@output_dir, "lib", @config.require_path)
    FileUtils.mkdir_p(lib_path)

    # RuboCop config shipped inside the gem (resolved via inherit_gem)
    render_template("lib/rubocop.yml", "lib/#{@config.require_path}/rubocop.yml")

    # Main require file
    render_template("lib/main.rb.erb", "lib/#{@config.require_path}.rb")

    # Version file
    render_template("lib/version.rb.erb", "lib/#{@config.require_path}/version.rb")

    # Test helper shipped inside the gem
    render_template("lib/test_helper.rb.erb", "lib/#{@config.require_path}/test_helper.rb")

    # Test directory with placeholder
    FileUtils.mkdir_p(File.join(@output_dir, "test"))
    render_template("test/test_helper.rb.erb", "test/test_helper.rb")
  end

  private def create_rust_extension
    ext_name = @config.gem_name.tr("-", "_")

    render_template("ext/Cargo.toml.erb", "ext/#{ext_name}/Cargo.toml")
    render_template("ext/extconf.rb.erb", "ext/#{ext_name}/extconf.rb")
    render_template("ext/.cargo/config.toml.erb", "ext/#{ext_name}/.cargo/config.toml")
    render_template("ext/.gitignore.erb", "ext/#{ext_name}/.gitignore")
    render_template("ext/clippy.toml.erb", "ext/#{ext_name}/clippy.toml")
    render_template("ext/src/lib.rs.erb", "ext/#{ext_name}/src/lib.rs")
  end

  private def generate_nested_module(parts, content, indent = 0, is_outermost = true)
    return content if parts.empty?

    prefix = "  " * indent
    first, *rest = parts
    inner = generate_nested_module(rest, content, indent + 1, false)
    inner_prefix = "  " * (indent + 1)

    if rest.empty?
      # Innermost module - content is a doc comment that goes BEFORE the module
      if content.empty?
        "#{prefix}module #{first}\n#{prefix}end"
      else
        "#{prefix}#{content}\n#{prefix}module #{first}\n#{prefix}end"
      end
    else
      # Outer modules get :nodoc: to avoid "missing documentation" warnings
      # (they're documented in the main require file or the core gem)
      nodoc = is_outermost ? " # :nodoc: Documented in the ratatui_ruby gem." : ""
      "#{prefix}module #{first}#{nodoc}\n#{inner}\n#{prefix}end"
    end
  end

  private def generate_nested_module_with_error(parts, indent = 0)
    prefix = "  " * indent
    if parts.length == 1
      # Innermost module with documented Error class
      <<~RUBY.chomp
        #{prefix}module #{parts.first}
        #{prefix}  # Base error class for this library.
        #{prefix}  #
        #{prefix}  # All library-specific exceptions inherit from this class.
        #{prefix}  # Catch this to handle any library error generically.
        #{prefix}  class Error < StandardError; end
        #{prefix}end
      RUBY
    else
      first, *rest = parts
      inner = generate_nested_module_with_error(rest, indent + 1)
      "#{prefix}module #{first}\n#{inner}\n#{prefix}end"
    end
  end

  private def generate_nested_module_with_version(parts, indent = 0, is_outermost = true)
    prefix = "  " * indent
    if parts.length == 1
      # Innermost module with documented VERSION constant
      <<~RUBY.chomp
        #{prefix}module #{parts.first}
        #{prefix}  # The version of this gem.
        #{prefix}  # See https://semver.org/spec/v2.0.0.html
        #{prefix}  VERSION = "0.0.0"
        #{prefix}end
      RUBY
    else
      first, *rest = parts
      inner = generate_nested_module_with_version(rest, indent + 1, false)
      # Outer modules get :nodoc: to avoid "missing documentation" warnings
      # (they're documented in the main require file or the core gem)
      nodoc = is_outermost ? " # :nodoc: Documented in the ratatui_ruby gem." : ""
      "#{prefix}module #{first}#{nodoc}\n#{inner}\n#{prefix}end"
    end
  end

  private def binding_for_config
    module_parts = @config.module_name.split("::")
    ext_name = @config.gem_name.tr("-", "_")

    # Create a binding with all config values available to templates
    b = binding
    b.local_variable_set(:gem_name, @config.gem_name)
    b.local_variable_set(:gem_display_name, @config.module_name)
    b.local_variable_set(:module_name, @config.module_name)
    b.local_variable_set(:require_path, @config.require_path)
    b.local_variable_set(:copyright_holder, @config.copyright_holder)
    b.local_variable_set(:license, @config.license)
    b.local_variable_set(:author, @config.author)
    b.local_variable_set(:email, @config.email)
    b.local_variable_set(:year, @config.year)
    b.local_variable_set(:has_rdoc, true)
    b.local_variable_set(:has_rust, @config.has_rust)
    b.local_variable_set(:rubies, @config.ruby_versions)
    b.local_variable_set(:ext_name, ext_name)
    b.local_variable_set(:nested_module, generate_nested_module(module_parts, "# Namespace for library functionality."))
    b.local_variable_set(:nested_module_with_version, generate_nested_module_with_version(module_parts))
    b.local_variable_set(:update_mode, @update_mode)
    b.local_variable_set(:dependencies, [])
    b.local_variable_set(:summary, "Part of the RatatuiRuby ecosystem")
    b.local_variable_set(:description, "#{@config.module_name} - part of the RatatuiRuby TUI framework ecosystem")
    b.local_variable_set(:github_repo, "setdef/#{@config.module_name}")
    b.local_variable_set(:project_name, @config.module_name)
    b.local_variable_set(:version_file_require, "lib/#{@config.require_path}/version")
    b.local_variable_set(:version_file, "lib/#{@config.require_path}/version.rb")
    b
  end
end
