# -*- encoding: utf-8 -*-
# stub: in_threads 1.5.2 ruby lib

Gem::Specification.new do |s|
  s.name = "in_threads".freeze
  s.version = "1.5.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/toy/in_threads/issues", "changelog_uri" => "https://github.com/toy/in_threads/blob/master/CHANGELOG.markdown", "documentation_uri" => "https://www.rubydoc.info/gems/in_threads/1.5.2", "source_code_uri" => "https://github.com/toy/in_threads" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ivan Kuchin".freeze]
  s.date = "2019-05-25"
  s.homepage = "http://github.com/toy/in_threads".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "Run all possible enumerable methods in concurrent/parallel threads".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_development_dependency(%q<rspec-retry>.freeze, ["~> 0.3"])
      s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.59"])
    else
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_dependency(%q<rspec-retry>.freeze, ["~> 0.3"])
      s.add_dependency(%q<rubocop>.freeze, ["~> 0.59"])
    end
  else
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<rspec-retry>.freeze, ["~> 0.3"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.59"])
  end
end
