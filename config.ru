# -*- mode: ruby; encoding: utf-8; -*-

$LOAD_PATH << File.expand_path("../lib", __FILE__)
require 'mogilefs_s3_device'
# require 'dav4rack'
require 'logger'
require 'aws-sdk'

MogilefsS3Device.logger = Logger.new(STDOUT)
MogilefsS3Device.bucket = "reverbnation-songs-development"
MogilefsS3Device.prefix = "public"
AWS.config({
    access_key_id: ENV['SEC_AMAZON_S3_ACCESS_KEY'],
    secret_access_key: ENV['SEC_AMAZON_S3_ACCESS_SECRET_KEY'],
    logger: MogilefsS3Device.logger
  })

use MogilefsS3Device::Cleanup
use Rack::Lint
use Rack::Logger, Logger::DEBUG
use Rack::CommonLogger
run MogilefsS3Device::Handler.new

# run DAV4Rack::Handler.new(root: File.expand_path("../public/files", __FILE__))

# run DAV4Rack::Handler.new({
#     resource_class: MogilefsS3Device::S3Resource,
#     log_to: MogilefsS3Device.logger
#   })
