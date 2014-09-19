# -*- encoding: utf-8; -*-

require 'rubygems'
require 'bundler/setup'
require 'mogilefs_s3_device'
require 'logger'
require 'aws-sdk'

MogilefsS3Device.logger = Logger.new(STDOUT)
MogilefsS3Device.bucket = "reverbnation-songs-development"
MogilefsS3Device.prefix = "mogilefs-backup"

MogilefsS3Device.db_settings = {
  host: "127.0.0.1",
  username: ENV['SEC_MOGILEFS_DATABASE_USERNAME'],
  password: ENV['SEC_MOGILEFS_DATABASE_PASSWORD'],
  database: "mogilefs",
  encoding: "utf8",
  reconnect: true,
}

AWS.config({
    access_key_id: ENV['SEC_AMAZON_S3_ACCESS_KEY'],
    secret_access_key: ENV['SEC_AMAZON_S3_ACCESS_SECRET_KEY'],
    logger: MogilefsS3Device.logger
  })
