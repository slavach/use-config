# vim:filetype=ruby

require File.dirname(__FILE__) + "/lib/use_config/version"

spec = Gem::Specification.new do |s|
  s.name = 'use-config'
  s.version = UseConfig::VERSION
  s.platform = Gem::Platform::RUBY
  s.author = 'Svetoslav Chernobay'
  s.email = 'slava@chernobay.info'
  s.homepage = 'http://github.com/slavach/use-config'
  s.summary = 'Easy configuration solution for any Ruby class'
  s.description = 'UseConfig library allows a Ruby class to use configuration stored in a YAML file'

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project = 'use-config'

  s.files = %w[ README.md LICENSE Rakefile ] + Dir.glob("{lib,spec}/*")
  s.require_paths = %w[ lib ]

  s.has_rdoc = true
  s.extra_rdoc_files = %w[ README.md LICENSE ]
  s.rdoc_options = %w[ --main=README --line-numbers --inline-source ]
end

