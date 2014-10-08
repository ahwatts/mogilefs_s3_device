# -*- encoding: utf-8; -*-

require 'mogilefs_s3_device/cleanup_middleware'
require 'mogilefs_s3_device/controller'
require 'mogilefs_s3_device/handler'
require 'mogilefs_s3_device/s3_accessors'
require 'mogilefs_s3_device/s3_proxy'
require 'mogilefs_s3_device/test_writer'
require 'mogilefs_s3_device/usage_stats'
require 'mogilefs_s3_device/version'
require 'connection_pool'
require 'mysql2'

module MogilefsS3Device
  class << self
    attr_accessor(:logger, :bucket, :prefix, :db_settings, :db_conn_pool,
      :free_space, :environment)

    def db_conn
      @db_conn_pool ||= ConnectionPool.new(size: 4, timeout: 2) do
        Mysql2::Client.new(self.db_settings)
      end
    end

    # Paper over a difference in API between Rubinius and MRI.
    def exception_cause(ex)
      if ex.respond_to?(:cause)
        ex.cause
      elsif ex.respond_to?(:parent)
        ex.parent
      else
        nil
      end
    end

    def log_error(request, exception = $!)
      msg = StringIO.new
      msg.puts("Error handling request %p %p: %s (%p):\n\t%s" %
        [ request.request_method, request.path_info,
          exception.message, exception.class,
          exception.backtrace.join("\n\t") ])

      if exception.respond_to?(:cause)
        c = exception_cause(exception)
        while c
          msg.puts("Caused by: %s (%p):\n\t%s" %
            [ c.message, c.class, c.backtrace.join("\n\t") ])
          c = c.cause
        end
      end

      logger.error(msg.string)
      log_error_to_remote(request, exception)
    end

    def log_error_to_remote(request, exception)
      if defined?(::Honeybadger) && !Honeybadger.configuration.api_key.nil?
        Honeybadger.notify_or_ignore(exception, {
            rack_env: request.env,
            environment_name: ENV["RACK_ENV"]
          })
      else
        logger.debug("Honeybadger not configured, not sending exception there.")
      end
    end
  end
end
