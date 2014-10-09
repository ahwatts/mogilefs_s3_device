# -*- mode: ruby; encoding: utf-8; -*-

require 'rubygems'

# Make sure we're using the version of the gem that came along with
# this config.ru file.
lib_path = File.expand_path("../lib", __FILE__)
unless $:.include?(lib_path)
  $:.unshift(lib_path)
end

require 'mogilefs_s3_device'
require 'mogilefs_s3_device/init'

use MogilefsS3Device::Cleanup
use Rack::Logger, Logger::INFO

# Unicorn helpfully includes the Rack::CommonLogger middleware for us.
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
