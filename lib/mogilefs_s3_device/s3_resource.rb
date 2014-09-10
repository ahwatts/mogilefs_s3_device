# -*- encoding: utf-8; -*-

require 'dav4rack'
require 'pry'

module MogilefsS3Device
  class S3Resource < DAV4Rack::Resource
    attr_accessor :logger

    def get(request, response)
      self.logger ||= (request.env["rack.logger"] || Logger.new("/dev/null"))

      if path =~ /\/$/
        response.body << "<h1>Ok</h1>\nDirectory listing disabled\n"
      end
    end
  end
end
