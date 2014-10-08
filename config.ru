# -*- mode: ruby; encoding: utf-8; -*-

require 'rubygems'
require 'bundler/setup'
require 'mogilefs_s3_device'
require 'mogilefs_s3_device/init'

use MogilefsS3Device::Cleanup
use Rack::Logger

unless defined?(Unicorn)
  use Rack::CommonLogger
end

begin
  require 'honeybadger'
  use Honeybadger::Rack::ErrorNotifier
rescue LoadError
  # Don't worry about it...
end

run MogilefsS3Device::Handler.new
