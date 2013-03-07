
require "helper"

class TestCPU < Bixby::TestCase

  def test_get_load

    input = " 22:33pm  up 210 days  4:27,  1 user,  load average: 0.31, 0.32, 0.29\n"
    load = Hardware::CPU.parse_load(input, 1)

    assert load
    assert_kind_of Hash, load
    assert_equal 3, load.keys.size
    assert_equal 0.31, load.values[0]
    assert_equal 0.32, load.values[1]
    assert_equal 0.29, load.values[2]

    load = Hardware::CPU.parse_load(input, 8)
    assert_equal 0.31/8, load.values[0]
    assert_equal 0.32/8, load.values[1]
    assert_equal 0.29/8, load.values[2]
  end

  def test_num_procs
    assert Hardware::CPU.num_processors > 0
  end

end
