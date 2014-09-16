# -*- encoding: utf-8; -*-

require 'rack/request'
require 'rack/response'
require 'mogilefs_s3_device/test_writer'

module MogilefsS3Device
  class Handler
    def call(env)
      case env['PATH_INFO']
      when "/"
        handle_root(env)
      when /\/dev[0-9]+\/usage/
        handle_usage(env)
      when /^\/dev[0-9]+\/test-write(?:$|\/)/
        TestWriter.new(env).respond
      when /^\/dev[0-9]+\/([0-9]+\/)*[0-9]+(?:$|\/)/
        S3Proxy.new(env).respond
      else
        handle_not_found(env)
      end
    end

    def logger
      MogilefsS3Device.logger
    end

    def handle_root(env)
      [ 200, { "Content-Type" => "text/plain" }, [ "Hi!\n" ] ]
    end

    def handle_usage(env)
      response = Rack::Response.new

      # Fake usage data.
      usage_data = {
        available: 259056232,
        device: "/dev/mapper/fedora_wingedlizard-home",
        disk: "/home/awatts/rubydev/workspace/shared/mogdata/dev2",
        time: 1410379593,
        total: 399027440,
        use: "36%",
        used: 139969504
      }

      response["Content-Type"] = "text/plain"
      response.body << usage_data.map { |k, v| "#{k}: #{v}" }.join("\n") + "\n"
      response.finish
    end

    def handle_not_found(env)
      if env['REQUEST_METHOD'] == 'HEAD'
        [ 404, {}, [] ]
      else
        [ 404, { "Content-Type" => "text/plain" }, [ "Not found\n" ] ]
      end
    end
  end
end
