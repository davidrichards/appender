# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{appender}
  s.version = "0.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Richards"]
  s.date = %q{2009-08-24}
  s.default_executable = %q{appender}
  s.description = %q{Appends configuration to files}
  s.email = %q{drichards@showcase60.com}
  s.executables = ["appender"]
  s.files = ["README.rdoc", "VERSION.yml", "bin/appender", "lib/appender.rb", "spec/appender_spec.rb", "spec/spec_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/davidrichards/appender}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Appends configuration to files}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<logrotate>, [">= 0"])
    else
      s.add_dependency(%q<logrotate>, [">= 0"])
    end
  else
    s.add_dependency(%q<logrotate>, [">= 0"])
  end
end
