
source "http://rubygems.org"

gem 'bixby-common'
gem 'bixby-client'
# gem 'bixby-common', :path => "../common"
# gem 'bixby-client', :path => "../client"

gem 'api-auth', :github => "chetan/api_auth", :branch => "bixby"
gem 'mixlib-shellout', '~> 1.3.0'

group :development do
  # used by all_metrics.rb
  gem "terminal-table"

  gem "rake"
  gem "bundler"
  gem "pry"
  gem "debugger",     :platforms => [ :mri_20, :mri_19 ]
  gem "debugger-pry", :require => "debugger/pry", :platforms => [ :mri_20, :mri_19 ]

  gem "test_guard", :git => "https://github.com/chetan/test_guard.git"
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
end

group :test do

  gem "webmock",      :require => false
  gem "mocha",        :require => false

  gem "micron",   :github => "chetan/micron"
  gem "easycov",  :github => "chetan/easycov"
  gem "coveralls", :require => false

  # needed by some tests/scripts
  gem "json", "~> 1.8"
  gem "mixlib-cli"
  gem "facter"
  gem "daemons"

  # annoying httpi warning
  gem "rubyntlm"
end
