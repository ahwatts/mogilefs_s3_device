# -*- mode: ruby; encoding: utf-8; -*-

$LOAD_PATH << File.expand_path("../lib", __FILE__)
require 'mogilefs_s3_device'
require 'dav4rack'

use Rack::Lint
use Rack::Logger, Logger::DEBUG
use Rack::CommonLogger
use MogilefsS3Device::UsageHandler
# run DAV4Rack::Handler.new(:root => File.expand_path("../public", __FILE__))
run DAV4Rack::Handler.new({
    resource_class: MogilefsS3Device::S3Resource,
    log_to: File.expand_path("../log/s3_device.log", __FILE__)
  })
