
require "helper"

class TestCPU < Bixby::TestCase

  parallelize_me!

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

  def test_options
    shell = systemu(bin("monitoring", "cpu_load.rb") + " --options")
    assert shell.success?
    assert_equal "{}\n", shell.stdout
  end

  def test_monitor
    shell = systemu(bin("monitoring", "cpu_load.rb") + " --monitor")
    assert shell.success?
    ret = MultiJson.load(shell.stdout)
    assert_kind_of Hash, ret
    assert_equal "OK", ret["status"]
    assert_kind_of Fixnum, ret["timestamp"]
    assert_equal "cpu.loadavg", ret["key"]
    assert_equal 3, ret["metrics"].first["metrics"].size
  end

  def test_usage_stats
    stats = Hardware::CPU::Stats.fetch
    assert stats
    assert stats.user > 0
    assert stats.system > 0
    assert stats.idle > 0

    total = stats.user+stats.system+stats.idle
    assert total > 99
    #assert total <= 101 # sometimes slightly more than 100 on osx
  end

end
