# -*- encoding: utf-8; -*-

require 'mogilefs_s3_device/usage_handler'
require 'mogilefs_s3_device/s3_resource'
require 'mogilefs_s3_device/version'
require 'mogilefs_s3_device/cleanup_middleware'

module MogilefsS3Device
  class << self
    attr_accessor :logger, :bucket, :prefix
  end
end
