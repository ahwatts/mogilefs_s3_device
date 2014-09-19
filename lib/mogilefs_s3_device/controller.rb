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
        MogilefsS3Device.log_error
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
