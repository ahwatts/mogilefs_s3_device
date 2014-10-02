# -*- encoding: utf-8; -*-

bind "tcp://10.255.1.114:7500"
# worker_processes 8
threads 1, 16
pidfile "/var/run/mogilefs_s3_device/puma.pid"
