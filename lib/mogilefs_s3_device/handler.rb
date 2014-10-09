# -*- encoding: utf-8; -*-

require 'time'
require 'rack/request'
require 'rack/response'
require 'mogilefs_s3_device/test_writer'
require 'mogilefs_s3_device/s3_proxy'
require 'mogilefs_s3_device/usage_stats'

module MogilefsS3Device
  class Handler
    def call(env)
      start_time = Time.now
      handler = "none"

      response =
        case env['PATH_INFO']
        when "/"
          handler = "root"
          [ 200, { "Content-Type" => "text/plain" }, [ "Hi!\n" ] ]
        when /\/dev[0-9]+\/usage/
          handler = "usage_stats"
          UsageStats.new(env).respond
        when /^\/dev[0-9]+\/test-write(?:$|\/)/
          handler = "test_writer"
          TestWriter.new(env).respond
        when /^\/dev[0-9]+\/([0-9]+\/)*[0-9]+(?:$|\/)/
          handler = "s3_proxy"
          S3Proxy.new(env).respond
        else
          handler = "not_found"
          if env['REQUEST_METHOD'] == 'HEAD'
            [ 404, {}, [] ]
          else
            [ 404, { "Content-Type" => "text/plain" }, [ "Not found\n" ] ]
          end
        end

      end_time = Time.now
      MogilefsS3Device.record_stat("handlers.#{handler}.#{response.first.to_i.to_s}.response_time", :t, end_time - start_time)

      response
    end
  end
end
