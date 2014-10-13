# -*- encoding: utf-8; -*-

bind "tcp://0.0.0.0:4000"
threads 1, 16
pidfile File.expand_path("../tmp/pids/puma.pid", __FILE__)
preload_app!

if @options[:daemon]
  stdout_redirect(
    File.expand_path("../log/mogilefs_s3_device.log", __FILE__),
    File.expand_path("../log/mogilefs_s3_device.log", __FILE__),
    true)
end
