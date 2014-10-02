# -*- mode: ruby; encoding: utf-8; -*-

require 'rubygems'
require 'bundler/setup'
require 'mogilefs_s3_device'
require 'mogilefs_s3_device/init'

use MogilefsS3Device::Cleanup
use Rack::Logger, Logger::INFO

unless defined?(Unicorn)
  use Rack::CommonLogger
end

run MogilefsS3Device::Handler.new
