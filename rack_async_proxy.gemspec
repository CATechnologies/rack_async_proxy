# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rack_async_proxy/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Saimon Moore"]
  gem.email         = ["saimon@saimonmoore.net"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rack_async_proxy"
  gem.require_paths = ["lib"]
  gem.version       = RackAsyncProxy::VERSION
end
