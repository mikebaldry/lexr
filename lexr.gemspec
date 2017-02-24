# -*- encoding: utf-8 -*-
# stub: lexr 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "lexr".freeze
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Baldry".freeze]
  s.date = "2017-02-24"
  s.email = "mikeyb@buyapowa.com".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze, "lib/lexr.rb".freeze]
  s.homepage = "http://tech.buyapowa.com".freeze
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.rubygems_version = "2.5.2".freeze
  s.summary = "A lightweight and pretty lexical analyser".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
  end
end
