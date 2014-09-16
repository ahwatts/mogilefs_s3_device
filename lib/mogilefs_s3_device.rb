# -*- encoding: utf-8; -*-

require 'mogilefs_s3_device/cleanup_middleware'
require 'mogilefs_s3_device/controller'
require 'mogilefs_s3_device/handler'
require 'mogilefs_s3_device/s3_accessors'
require 'mogilefs_s3_device/s3_proxy'
require 'mogilefs_s3_device/test_writer'
require 'mogilefs_s3_device/usage_stats'
require 'mogilefs_s3_device/version'

module MogilefsS3Device
  class << self
    attr_accessor :logger, :bucket, :prefix
  end
end
