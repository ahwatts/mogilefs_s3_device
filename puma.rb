# -*- encoding: utf-8; -*-

bind "tcp://0.0.0.0:4000"
threads 1, 16
pidfile "tmp/pids/puma.pid"

if @options[:daemon]
  stdout_redirect(
    "log/mogilefs_s3_device.log",
    "log/mogilefs_s3_device.log",
    true)
end
