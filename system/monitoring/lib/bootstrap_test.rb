
# add helper(s)
begin; require 'awesome_print'; rescue LoadError; end
begin; require 'turn'; rescue LoadError; end

gem 'minitest'
require 'minitest/unit'

class MiniTest::Unit::TestCase
end

MiniTest::Unit.autorun
