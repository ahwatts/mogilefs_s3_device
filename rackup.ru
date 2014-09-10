# -*- mode: ruby; encoding: utf-8; -*-

$LOAD_PATH << File.expand_path("../lib", __FILE__)
require 'mogilefs_s3_device'
require 'dav4rack'

use Rack::Lint
use Rack::Logger, Logger::DEBUG
use Rack::CommonLogger
use MogilefsS3Device::UsageHandler
run DAV4Rack::Handler.new(:root => File.expand_path("../public", __FILE__))
