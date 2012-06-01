# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "lexr"
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Baldry"]
  s.date = "2012-06-01"
  s.email = "michael.baldry@uswitch.com"
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md", "spec", "lib/lexr.rb"]
  s.homepage = "http://www.forwardtechnology.co.uk"
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.21"
  s.summary = "A lightweight and pretty lexical analyser"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
