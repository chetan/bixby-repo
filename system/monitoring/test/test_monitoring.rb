
require "helper"

class TestMonitoring < Bixby::TestCase

  parallelize_me!

  old_wd = Dir.pwd
  Dir.chdir(BIXBY_REPO_PATH)
  files = Dir.glob("./**/*.rb")
  Dir.chdir(old_wd)

  files.each do |file|
    next if file !~ %r{/bin/monitoring/}
    file.slice!(0..1)
    cmd = file.slice(0..-4).gsub(%r{bin/monitoring/}, '').gsub(%r{/}, '_')
    code = <<-EOF
      def test_#{cmd}
        do_test_mon("#{file}")
      end
    EOF
    eval(code)
  end


  private

  # test the given monitoring plugin/script
  def do_test_mon(file)
    config = file + ".json"
    assert File.exist?(config), "has config file"

    config = MultiJson.load(File.read(config))
    assert config
    assert_kind_of Hash, config

    refute_empty config["name"], "has a name"
    refute_empty config["key"], "has a key"

    if config["options"] then
      do_test_options(file, config["options"])
    end

    do_test_metrics(file, config["metrics"])
  end

  # test the options command
  def do_test_options(file, options)
    return if options.empty?

    shell = systemu(full_path(file) + " --options")

    puts shell.stdout if debug?
    puts shell.stderr if debug?

    assert shell.success?
    assert_empty shell.stderr
    refute_empty shell.stdout

    opts = MultiJson.load(shell.stdout)
    assert opts
    ap opts if debug?
    assert_kind_of Hash, opts

    options.each do |key, opt_desc|

      assert_includes opt_desc, "type", "option has a type"
      assert_includes opt_desc, "name", "option has a name"
      assert_includes opt_desc, "desc", "option has a desc"

      assert_includes opts, key
      val = opts[key]
      assert val

      case opt_desc["type"]
      when "enum"
        assert_kind_of Array, val
        refute_empty val

      end
    end

  end

  # test the monitoring command
  def do_test_metrics(file, metrics)

    file = full_path(file)

    opts = {}
    if File.exist? "#{file}.test" then
      opts[:input] = File.read("#{file}.test")
    end

    shell = systemu(file + " --monitor", opts)
    puts shell.stdout if debug?
    puts shell.stderr if debug?
    assert shell.success?

    storage = Dir.glob(Bixby.path("var", "monitoring", "data", "**")).first
    if storage and File.exist? storage and File.size(storage) > 4 then
      # run command twice in case storage/recall is required for generating metrics
      shell = systemu(full_path(file) + " --monitor", opts)
      assert shell.success?
    end

    puts shell.stdout if debug?
    puts shell.stderr if debug?

    assert_empty shell.stderr
    refute_empty shell.stdout

    ret = MultiJson.load(shell.stdout)
    assert ret
    ap ret if debug?

    assert_includes ret, "timestamp"
    assert_includes ret, "status"
    assert_includes ret, "check_id"
    assert_includes ret, "key"
    assert_includes ret, "metrics"
    assert_includes ret, "errors"

    assert_kind_of Fixnum, ret["timestamp"]
    assert ret["timestamp"] > 10000
    assert_equal "OK", ret["status"]
    refute_empty ret["key"]
    assert_empty ret["errors"]

    metrics.each do |key, mdesc|

      assert_includes mdesc, "desc", "metric has a description"

      # make sure the metric appears in the result
      if mdesc.include? "platforms" then
        if mdesc["platforms"].include? "linux" and linux? then
          assert_metric_present(ret["metrics"], key, mdesc["range"])
        elsif mdesc["platforms"].include? "osx" and osx? then
          assert_metric_present(ret["metrics"], key, mdesc["range"])
        end

      else
        assert_metric_present(ret["metrics"], key, mdesc["range"])
      end

    end

    ret["metrics"].each do |r|
      assert_includes r, "metrics"
      assert_includes r, "metadata"
    end
  end

  def assert_metric_present(metrics, key, range)
    vals = metrics.find_all{ |r| r["metrics"].include? key }
    refute_empty vals, "should report metric #{key}"
    val = vals.first["metrics"][key]
    assert val
    assert_kind_of Numeric, val

    return if range.nil?
    range.strip!

    # >= 0
    if range == "0+" then
      assert val >= 0

    # val <= foo
    elsif range =~ /<=([\d.-]+)/ then
      assert val <= $1.to_f

    # val >= foo
    elsif range =~ />=([\d.-]+)/ then
      assert val >= $1.to_f

    # val < foo
    elsif range =~ /<([\d.-]+)/ then
      assert val < $1.to_f

    # val > foo
    elsif range =~ />([\d.-]+)/ then
      assert val > $1.to_f

    # val in range A..B
    elsif range =~ /([\d.-]+)\.\.([\d.-]+)/ then
      range = $1.to_f..$2.to_f
      assert range.include?(val)
    end

  end

  def full_path(file)
    return File.join(Bixby.repo_path, "vendor", file)
  end

  def debug?
    ENV["DEBUG"]
  end

end
