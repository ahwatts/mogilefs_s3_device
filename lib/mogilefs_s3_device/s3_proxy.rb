# -*- encoding: utf-8; -*-

require 'aws-sdk'

module MogilefsS3Device
  class S3Proxy
    def initialize(request)
      @s3 = AWS::S3.new
      @bucket = @s3.buckets[MogilefsS3Device.bucket]
      @key = MogilefsS3Device.prefix + request.path_info
      @object = @bucket.objects[@key]
    end

    def s3_meta
      if !@tried_object
        begin
          @s3_meta = @object.head
        rescue AWS::S3::Errors::NoSuchKey
          @s3_meta = nil
        end
        @tried_object = true
      end
      @s3_meta
    end

    def handle(request, response)
      case request.request_method
      when 'GET', 'HEAD'
        if !s3_meta.nil?
          logger.debug("s3_meta = #{s3_meta.inspect}")
          response.status = 200
          response["Content-Type"] = s3_meta[:content_type].to_s
          response["Content-Length"] = s3_meta[:content_length].to_s
          response["Etag"] = s3_meta[:etag].to_s
          response["Last-Modified"] = s3_meta[:last_modified].to_s
          if request.request_method == 'GET'
            response.body = [ @object.read ]
          end
        else
          not_found(request, response)
        end
      when 'PUT'
        @object.write(request.body.read, content_type: request.content_type)
        response.status = 204
        response.body = []
      when 'DELETE'
        if @object.exists?
          @object.delete
          response.status = 204
          response.body = []
        else
          not_found(request, response)
        end
      else
        response.status = 400
        response["Content-Type"] = "text/plain"
        response.body << "Request was not understood."
      end
    end

    def not_found(request, response)
      response.status = 404
      response["Content-Type"] = "text/plain"
      response.body << "This file does not exist.\n"
    end

    def logger
      MogilefsS3Device.logger
    end
  end
end
