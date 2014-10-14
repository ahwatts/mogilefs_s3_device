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
require 'socket'

module MogilefsS3Device
  class << self
    # The environment to run in, for switching settings as necessary.
    attr_accessor :environment

    # The S3 bucket.
    attr_accessor :bucket

    # The prefix on keys in the S3 bucket.
    attr_accessor :prefix

    # The main app logger.
    attr_accessor :logger

    # How much free space to report back to MogilefS (in KiB).
    attr_accessor :free_space

    # The settings to connect to the database.
    attr_accessor :db_settings

    # The host and port for reporting statsd information to.
    attr_accessor :statsd_host, :statsd_port

    # The namespace for the statsd information to report.
    attr_accessor :statsd_prefix

    # Retrieve the pool of database connections.
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

    # Logs an exception to both the local logger and Honeybadger, if
    # available.
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
      log_error_to_statsd(request, exception)
    end

    # Logs an exception to Honeybadger if it's enabled.
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

    def record_stat(name, type, value = nil, by_host = true)
      if defined?(::Statsd) && (!@statsd.nil? || (statsd_host && statsd_port.to_i > 0))
        @statsd ||= Statsd.new(statsd_host, statsd_port).tap do |s|
          s.namespace = statsd_prefix
        end

        full_name =
          if by_host
            "m_#{Socket.gethostname.split('.').first}.#{name}"
          else
            "all.#{name}"
          end


        case type
        when :counter, :c
          @statsd.increment(full_name, (value || 1).to_i)
        when :timing, :t
          @statsd.timing(full_name, value.to_i)
        when :gauge, :g
          @statsd.gauge(full_name, value.to_i)
        end
      end
    end

    # Cribbed from ActiveSupport.
    def underscore(camel_cased_word)
      word = camel_cased_word.to_s.gsub('::', '/')
      # word.gsub!(/(?:([A-Za-z\d])|^)(#{inflections.acronym_regex})(?=\b|[^a-z])/) { "#{$1}#{$1 && '_'}#{$2.downcase}" }
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end

    def log_error_to_statsd(request, exception)
      ex_key = nil
      if RuntimeError === exception
        ex_key = exception.message.gsub(/[^A-Za-z0-9]/, " ").squeeze(" ").downcase.slice(0, 15)
      else
        ex_key = underscore(exception.class.name.downcase.split("::").join("")).slice(0, 15)
      end

      record_stat("exceptions.#{ex_key}", :c)
    end
  end
end
