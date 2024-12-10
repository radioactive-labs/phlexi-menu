# frozen_string_literal: true

require_relative "lib/phlexi/menu/version"

Gem::Specification.new do |spec|
  spec.name = "phlexi-menu"
  spec.version = Phlexi::Menu::VERSION
  spec.authors = ["Stefan Froelich"]
  spec.email = ["sfroelich01@gmail.com"]

  spec.summary = "A flexible and powerful menu builder for Ruby applications"
  spec.description = "Phlexi::Menu is a flexible menu builder for Ruby applications that provides hierarchical menus, active state detection, icons, badges, and a powerful theming system. Built with Phlex components, it offers a modern approach to building navigation menus."
  spec.homepage = "https://github.com/radioactive-labs/phlexi-menu"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.2"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "phlex", "~> 1.11"
  spec.add_dependency "zeitwerk"
  spec.add_dependency "phlexi-field"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "standard"
  # spec.add_development_dependency "brakeman"
  spec.add_development_dependency "bundle-audit"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "combustion"
  spec.add_development_dependency "phlex-testing-capybara"
end
