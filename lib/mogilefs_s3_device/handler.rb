# -*- encoding: utf-8; -*-

require 'rack/request'
require 'rack/response'
require 'mogilefs_s3_device/test_writer'
require 'mogilefs_s3_device/s3_proxy'
require 'mogilefs_s3_device/usage_stats'

module MogilefsS3Device
  class Handler
    def call(env)
      case env['PATH_INFO']
      when "/"
        [ 200, { "Content-Type" => "text/plain" }, [ "Hi!\n" ] ]
      when /\/dev[0-9]+\/usage/
        UsageStats.new(env).respond
      when /^\/dev[0-9]+\/test-write(?:$|\/)/
        TestWriter.new(env).respond
      when /^\/dev[0-9]+\/([0-9]+\/)*[0-9]+(?:$|\/)/
        S3Proxy.new(env).respond
      else
        if env['REQUEST_METHOD'] == 'HEAD'
          [ 404, {}, [] ]
        else
          [ 404, { "Content-Type" => "text/plain" }, [ "Not found\n" ] ]
        end
      end
    end
  end
end
