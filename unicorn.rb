# -*- encoding: utf-8; -*-

listen 4000
worker_processes 8
pid "tmp/pids/unicorn.pid"

before_fork do |server, worker|
  # Single server rolling reaper.
  # 1. Start new master, flag old as old
  # 2. Bring up 1 new worker and request old master gently kill one worker
  # 3. Repeat until all old workers are dead
  # 4. Reap old master
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end

  sleep 1 # Time between each new worker thread start (single thread warmup period)
end

if RACKUP[:daemonized]
  stdout_path "log/mogilefs_s3_device.log"
  stderr_path "log/mogilefs_s3_device.log"
end
