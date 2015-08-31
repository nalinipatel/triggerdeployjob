source "https://rubygems.org"

gem 'rake', :group => [:development, :test]

group :development do
    gem 'puppet-syntax'
    gem 'pry'
    gem 'puppet-lint'
end

group :test do
    gem 'puppet', "~> 3.6"
    gem 'puppetlabs_spec_helper'
    gem 'rspec', "< 2.99"
    gem 'rspec-puppet', "2.2.0"
    gem 'yarjuf' #Rspec Junit formatter
end
