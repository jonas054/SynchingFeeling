source 'http://rubygems.org'

gemspec

group :test do
  gem 'coveralls', '~> 0.8.23', require: false
end

local_gemfile = 'Gemfile.local'

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
end
