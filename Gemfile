
source "http://rubygems.org"

gem 'bixby-common'
gem 'bixby-client'
# gem 'bixby-common', :path => "../common"
# gem 'bixby-client', :path => "../client"

group :development, :test do

  gem "bundler"
  gem "pry"
  gem "debugger",     :platforms => [ :mri_20, :mri_19 ]
  gem "debugger-pry", :require => "debugger/pry", :platforms => [ :mri_20, :mri_19 ]

  gem "simplecov",    :platforms => [:mri_20, :mri_19, :rbx], :git => "https://github.com/chetan/simplecov.git", :branch => "inline_nocov"

  gem "minitest",     :platforms => [:mri_20, :mri_19, :rbx]
  gem "webmock",      :require => false
  gem "mocha",        :require => false
  gem "parallel",     :require => false

  gem "turn",       :git => "https://github.com/chetan/turn.git", :branch => "parallel"
  gem "test_guard", :git => "https://github.com/chetan/test_guard.git"
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false

  # needed by some tests
  gem "mixlib-cli"
  gem "facter"
  gem "daemons"

end

