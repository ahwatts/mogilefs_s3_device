# -*- encoding: utf-8; -*-

require 'rack/request'
require 'rack/response'

module MogilefsS3Device
  class Handler
    def initialize
      @test_writes = TestWrites.new
    end

    def call(env)
      request = Rack::Request.new(env)

      case request.path_info
      when "/"
        handle_root(env)
      when /\/dev[0-9]+\/usage/
        handle_usage(env)
      when /^\/dev[0-9]+\/test-write(?:$|\/)/
        handle_test_write(env)
      when /^\/dev[0-9]+\/([0-9]+\/)*[0-9]+(?:$|\/)/
        handle_actual_file(env)
      else
        handle_not_found(env)
      end
    end

    def logger
      MogilefsS3Device.logger
    end

    def handle_actual_file(env)
      request = Rack::Request.new(env)
      response = Rack::Response.new

      case request.request_method
      when 'GET', 'HEAD', 'PUT', 'DELETE'
        s3_proxy = S3Proxy.new(request)
        logger.debug("actual file: #{request.request_method}: #{s3_proxy.inspect}")
        s3_proxy.handle(request, response)
      when 'MKCOL'
        logger.debug("actual file: ignoring mkcol")
        response.status = 400
        response["Content-Type"] = "text/plain"
        response.body << "This server doesn't handle directories.\n"
      else
        logger.debug("actual file: Unknown request method: #{request.request_method.inspect}")
        response.status = 400
        response["Content-Type"] = "text/plain"
        response.body << "Unknown request.\n"
      end

      response.finish
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

    def handle_test_write(env)
      request = Rack::Request.new(env)
      response = Rack::Response.new

      case env['REQUEST_METHOD']
      when 'GET'
        write = @test_writes.get_write(request.path_info)
        if write
          response.status = 200
          response["Content-Type"] = write.content_type
          response.body << write.content
        else
          response.status = 404
          response["Content-Type"] = "text/plain"
          response.body << "Not found.\n"
        end
      when 'PUT'
        @test_writes.put_write(request.path_info, request.content_type, request.body.read)
        response.status = 200
        response["Content-Type"] = "text/plain"
        response.body << "Wrote it!.\n"
      when 'MKCOL'
        response.status = 400
        response["Content-Type"] = "text/plain"
        response.body << "This server doesn't handle directories.\n"
      else
        response.status = 404
        response["Content-Type"] = "text/plain"
        response.body << "Not found.\n"
      end

      response.finish
    end

    def handle_not_found(env)
      [ 404, { "Content-Type" => "text/plain" }, [ "Not found\n" ] ]
    end
  end
end
