
source "http://rubygems.org"

gem 'bixby-common'
gem 'bixby-client'
# gem 'bixby-common', :path => "../common"
# gem 'bixby-client', :path => "../client"

group :development, :test do

  gem "rake"

  # used by all_metrics.rb
  gem "terminal-table"

  gem "bundler"
  gem "pry"
  gem "debugger",     :platforms => [ :mri_20, :mri_19 ]
  gem "debugger-pry", :require => "debugger/pry", :platforms => [ :mri_20, :mri_19 ]

  gem "simplecov",    "=0.8.0.pre2", :platforms => [:mri_20, :mri_19, :rbx]
  gem "simplecov-html", :github => "chetan/simplecov-html", :branch => "colorbox"

  gem "minitest",     "~> 4.7", :platforms => [:mri_20, :mri_19, :rbx]
  gem "webmock",      :require => false
  gem "mocha",        :require => false

  gem "test_guard", :git => "https://github.com/chetan/test_guard.git"
  gem "coveralls", :require => false
  gem "easycov", :github => "chetan/easycov"
  gem "micron", :github => "chetan/micron"

  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false

  # needed by some tests/scripts
  gem "json", "~> 1.8"
  gem "mixlib-cli"
  gem "facter"
  gem "daemons"

end

