
require "helper"

class TestGetBundle < Bixby::TestCase

  def test_get_bundle

    require_script()

    # test provision class
    cmd = Bixby::CommandSpec.new({
        :repo => "support",
        :bundle => "test_bundle",
        :command => "echo",
        :digest => "5ca36fa0f9bd59e8169cc379215e6a481363df5b1e745f0442170fe6a56e1118" })

    cmd_hash = MultiJson.load(cmd.to_json)
    provisioner = Bixby::Provision.new
    provisioner.stubs(:get_json_input).returns(cmd_hash.dup, cmd_hash.dup)

    # setup our expectations on the run method
    ret_list = Bixby::JsonResponse.from_json('{"status":"success","message":null,"data":[{"file":"bin/echo","digest":"abcd"}],"code":null}')
    Bixby.client.expects(:exec_api).times(2).with{|req| puts req; true}.returns(ret_list)
    Bixby.client.expects(:exec_api_download).times(2).with{ |req, filename|
        dir = File.dirname(filename)
        assert File.exists? dir
        assert File.directory? dir
        `cp -a #{@test_bundle_path} #{Bixby.home}/repo/support/` # copy whole bundle
        true
        }.returns(true)

    provisioner.run

    assert File.exists? cmd.command_file
    assert File.file? cmd.command_file
    assert File.executable? cmd.command_file

    # try changing the digest hash and run again. it should trigger another (second) download
    cmd.digest = "changed_hash"
    cmd_hash = MultiJson.load(cmd.to_json)
    provisioner.stubs(:get_json_input).returns(cmd_hash.dup, cmd_hash.dup)
    provisioner.run

    # run again, no change (client expectations won't fire again)
    cmd.digest = "5ca36fa0f9bd59e8169cc379215e6a481363df5b1e745f0442170fe6a56e1118"
    cmd_hash = MultiJson.load(cmd.to_json)
    provisioner.stubs(:get_json_input).returns(cmd_hash.dup, cmd_hash.dup)
    puts
    puts
    puts "last run........."
    p cmd.load_digest
    provisioner.run
  end

  def test_bad_json
    require_script()

    provisioner = Bixby::Provision.new
    provisioner.stubs(:get_json_input).returns(nil)

    assert_throws(SystemExit) do
      provisioner.run
    end

  end


  private

  def require_script
    assert require(bin("get_bundle.rb"))
    assert Bixby.const_defined?(:Provision)
  end

end
