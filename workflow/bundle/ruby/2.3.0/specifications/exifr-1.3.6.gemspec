# -*- encoding: utf-8 -*-
# stub: exifr 1.3.6 ruby lib

Gem::Specification.new do |s|
  s.name = "exifr".freeze
  s.version = "1.3.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["R.W. van 't Veer".freeze]
  s.date = "2019-02-10"
  s.description = "EXIF Reader is a module to read EXIF from JPEG and TIFF images.".freeze
  s.email = "exifr@remworks.net".freeze
  s.executables = ["exifr".freeze]
  s.files = ["bin/exifr".freeze]
  s.homepage = "http://github.com/remvee/exifr/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7".freeze)
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "Read EXIF from JPEG and TIFF images".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<test-unit>.freeze, ["= 3.1.5"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10"])
    else
      s.add_dependency(%q<test-unit>.freeze, ["= 3.1.5"])
      s.add_dependency(%q<rake>.freeze, ["~> 10"])
    end
  else
    s.add_dependency(%q<test-unit>.freeze, ["= 3.1.5"])
    s.add_dependency(%q<rake>.freeze, ["~> 10"])
  end
end
