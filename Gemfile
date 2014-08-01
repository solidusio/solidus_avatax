source 'https://rubygems.org'

gem 'vcr'
gem 'webmock'
gem 'pry'
gem 'timecop'

gemspec

# TODO: Remove this completely whenever we upgrade spree_avatax to Spree 2.4+
gem 'spree_core', git: 'git@github.com:bonobos/spree.git', branch: '2-2-dev'

group :test, :development do
  platforms :ruby_19 do
    gem 'pry-debugger'
  end
  platforms :ruby_20, :ruby_21 do
    gem 'pry-byebug'
  end
end
