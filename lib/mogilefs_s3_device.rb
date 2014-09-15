# -*- encoding: utf-8; -*-

require 'mogilefs_s3_device/version'
require 'mogilefs_s3_device/handler'
require 'mogilefs_s3_device/test_writes'
require 'mogilefs_s3_device/s3_proxy'
require 'mogilefs_s3_device/cleanup_middleware'

module MogilefsS3Device
  class << self
    attr_accessor :logger, :bucket, :prefix
  end
end
