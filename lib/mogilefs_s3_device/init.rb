# -*- encoding: utf-8; -*-

require 'rubygems'
require 'bundler/setup'

# ms3d_load_path = File.expand_path("../lib", __FILE__)
# unless $LOAD_PATH.include?(ms3d_load_path)
#   $LOAD_PATH << ms3d_load_path
# end

require 'mogilefs_s3_device'
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
