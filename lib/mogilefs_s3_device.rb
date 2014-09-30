# -*- encoding: utf-8; -*-

require 'mogilefs_s3_device/cleanup_middleware'
require 'mogilefs_s3_device/controller'
require 'mogilefs_s3_device/handler'
require 'mogilefs_s3_device/s3_accessors'
require 'mogilefs_s3_device/s3_proxy'
require 'mogilefs_s3_device/test_writer'
require 'mogilefs_s3_device/usage_stats'
require 'mogilefs_s3_device/version'
require 'mysql2'

module MogilefsS3Device
  class << self
    attr_accessor :logger, :bucket, :prefix, :db_settings, :db_conn, :free_space

    def db_conn
      @db_conn ||= Mysql2::Client.new(self.db_settings)
    end

    def log_error(request, exception = $!)
      msg = StringIO.new
      msg.puts("Error handling request %p %p: %s (%p):\n\t%s" %
        [ request.request_method, request.path_info,
          exception.message, exception.class,
          exception.backtrace.join("\n\t") ])

      c = exception.cause
      while c
        msg.puts("Caused by: %s (%p):\n\t%s" %
          [ c.message, c.class, c.backtrace.join("\n\t") ])
        c = c.cause
      end

      logger.error(msg.string)
    end
  end
end
