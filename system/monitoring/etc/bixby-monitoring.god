
God.watch do |w|
  w.dir      = BIXBY_HOME
  w.name     = "bixby-monitoring"
  w.group    = "bixby"
  w.log      = "#{BIXBY_HOME}/var/god.#{w.name}.log"
  w.pid_file = "#{BIXBY_HOME}/var/#{w.name}.pid"

  w.interval = 30.seconds

  w.env      = {}

  mon_script = "#{BIXBY_RUN} run repo/vendor/system/monitoring/bin/mon_daemon.rb"
  w.start    = "#{mon_script} start"
  w.stop     = "#{mon_script} stop"

  w.start_grace = 10.seconds
  w.restart_grace = 10.seconds

  # other scripts may drop privs
  # w.uid = USER
  # w.gid = GROUP

  w.behavior(:clean_pid_file)

  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end

    # failsafe
    on.condition(:tries) do |c|
      c.times = 8
      c.within = 2.minutes
      c.transition = :start
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_exits)
  end

  # restart if memory gets too high
  w.transition(:up, :restart) do |on|
    on.condition(:memory_usage) do |c|
      c.above = 250.megabytes
      c.times = 2
    end
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end

end
