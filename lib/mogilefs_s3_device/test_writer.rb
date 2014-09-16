# -*- encoding: utf-8; -*-

require 'mogilefs_s3_device/controller'
require 'mogilefs_s3_device/s3_accessors'

module MogilefsS3Device
  class TestWriter < Controller
    include S3Accessors

    def initialize(*args)
      super(*args)
      self.key = MogilefsS3Device.prefix + request.path_info
    end

    def get
      if metadata.nil?
        not_found
      else
        respond_with_object(request, response)
      end
    end

    def put
      store_to_object(request.body,
        content_type: request.content_type,
        content_length: request.content_length.to_i)
      response.status = 204
      response.body = []
    end

    def mkcol
      bad_request("This server doesn't support directories.")
    end
  end
end
