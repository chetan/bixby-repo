
require "helper"

class TestListFacts < Bixby::TestCase

  def test_list_facts
    shell = systemu(bin("list_facts.rb"))
    assert shell.success?
    ret = MultiJson.load(shell.stdout)
    assert_kind_of Hash, ret
    assert_includes ret, "architecture"
    assert_includes ret, "kernel"
    assert_includes ret, "netmask"
  end

end
