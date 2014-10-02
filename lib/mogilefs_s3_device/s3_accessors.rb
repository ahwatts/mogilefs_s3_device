# -*- encoding: utf-8; -*-

require 'aws-sdk'

module MogilefsS3Device
  module S3Accessors
    attr_accessor :s3, :bucket, :key, :object, :metadata

    def s3
      @s3 ||= AWS::S3.new
    end

    def bucket
      @bucket ||= s3.buckets[MogilefsS3Device.bucket]
    end

    def object
      @object ||= bucket.objects[key]
    end

    def metadata
      unless @checked_metadata
        begin
          @metadata = object.head
        rescue AWS::S3::Errors::NoSuchKey
          @metadata = nil
        end
        @checked_metadata = true
      end
      @metadata
    end

    def reset_cached_s3_data
      @s3 = @bucket = @object = @metadata = @checked_metadata = nil
    end

    def respond_with_object(request, response, status = 200)
      response.status = status
      response["Content-Length"] = metadata[:content_length].to_s
      response["Content-Type"] = metadata[:content_type]
      response["ETag"] = metadata[:etag]
      response["Last-Modified"] = metadata[:last_modified].rfc2822
      unless request.request_method == 'HEAD'
        # Yikes.
        response.body = [ object.read ]
      end
    end

    def store_to_object(io, options = {}) # content_type: 'application/octet-stream', content_length:)
      content_type = options[:content_type] || 'application/octet-stream'
      content_length = options[:content_length].to_i
      object.write(io.read, content_type: content_type, content_length: content_length)
    end
  end
end
