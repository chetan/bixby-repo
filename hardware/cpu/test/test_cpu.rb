
require "helper"

class TestCPU < Bixby::TestCase

  def test_get_load

    input = " 22:33pm  up 210 days  4:27,  1 user,  load average: 0.31, 0.32, 0.29\n"
    load = Hardware::CPU.parse_load(input)

    assert load
    assert_equal Hash, load.class
    assert_equal 3, load.keys.size
    assert_equal 0.31, load.values.first
    assert_equal 0.29, load.values.last

  end

end
