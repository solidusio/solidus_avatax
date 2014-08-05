source 'https://rubygems.org'

gem 'vcr'
gem 'webmock'
gem 'pry'
gem 'timecop'

gemspec

group :test, :development do
  platforms :ruby_19 do
    gem 'pry-debugger'
  end
  platforms :ruby_20, :ruby_21 do
    gem 'pry-byebug'
  end
end
