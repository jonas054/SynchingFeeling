# encoding: utf-8

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'SynchingFeeling/version'
require 'English'

Gem::Specification.new do |s|
  s.name = 'SynchingFeeling'
  s.version = SynchingFeeling::Version::STRING
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.3'
  s.authors = ['Jonas Arvidsson']
  s.description = <<-EOF
    Uploader of directory trees full of photos to Flickr.
  EOF

  s.files = `git ls-files`.split($RS)
  s.test_files = s.files.grep(/^spec\//)
  s.executables = s.files.grep(/^bin\//) { |f| File.basename(f) }
  s.extra_rdoc_files = ['LICENSE', 'README.md']
  s.homepage = 'http://github.com/jonas054/SynchingFeeling'
  s.licenses = ['MIT']
  s.require_paths = ['lib']
  s.rubygems_version = '1.8.23'
  s.summary = 'Uploader of directory trees full of photos to Flickr.'

  s.add_runtime_dependency('flickraw', '~> 0.9')
  s.add_development_dependency('rake', '~> 10.1')
  s.add_development_dependency('rspec', '~> 3.0')
  s.add_development_dependency('bundler', '~> 1.3')
  s.add_development_dependency('simplecov', '~> 0.7')
end
