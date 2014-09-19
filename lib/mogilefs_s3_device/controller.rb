# -*- encoding: utf-8; -*-

module MogilefsS3Device
  class Controller
    attr_accessor :request, :response

    def initialize(env)
      self.request = Rack::Request.new(env)
      self.response = Rack::Response.new
    end

    def respond
      begin
        method = request.request_method.downcase.to_sym
        if respond_to?(method)
          send(method)
        else
          error
        end
      rescue
        msg = StringIO.new
        msg.puts("Error handling request %p %p: %s (%p):\n\t%s" %
          [ request.request_method, request.path_info, $!.message,
            $!.class, $!.backtrace.join("\n\t") ])

        c = $!.cause
        while c
          msg.puts("Caused by: %s (%p):\n\t%s" %
            [ c.message, c.class, c.backtrace.join("\n\t") ])
          c = c.cause
        end

        logger.error(msg.string)
        error
      end

      response.finish
    end

    protected

    def head?
      request.request_method == 'HEAD'
    end

    def logger
      MogilefsS3Device.logger
    end

    def no_content
      response.status = 204
      response.body = []
    end

    def bad_request(message = "Bad request.")
      response.status = 400
      unless head?
        response["Content-Type"] = "text/plain"
        response.body = [ "#{message}\n" ]
      end
    end

    def not_found
      response.status = 404
      unless head?
        response["Content-Type"] = "text/plain"
        response.body = [ "Not found.\n" ]
      end
    end

    def error(message = "There was an error processing the request.")
      response.status = 500
      unless head?
        response["Content-Type"] = "text/plain"
        response.body = [ "#{message}\n" ]
      end
    end
  end
end
