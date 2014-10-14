# -*- encoding: utf-8; -*-

require 'time'
require 'aws-sdk'
require 'forwardable'

module MogilefsS3Device
  class StatsdHttpHandler
    extend Forwardable

    def_delegators :@handler, :pool

    def initialize(real_handler)
      @handler = real_handler
    end

    def handle(request, response, &read_block)
      start_time = Time.now
      rv = @handler.handle(request, response, &read_block)
      end_time = Time.now

      up_bytes = request.headers["content-length"].to_i
      down_bytes = (response.headers["content-length"] || [ "0" ]).first.to_i

      MogilefsS3Device.record_stat("s3_ops.response_time", :t, ((end_time - start_time)*1000).round)
      MogilefsS3Device.record_stat("s3_ops.#{request.http_method}.#{response.status}", :c)

      if up_bytes > 0
        MogilefsS3Device.record_stat("s3_ops.up_bytes", :c, up_bytes)
      end

      if down_bytes > 0 && request.http_method != "HEAD"
        MogilefsS3Device.record_stat("s3_ops.down_bytes", :c, down_bytes)
      end

      rv
    end

    def logger
      MogilefsS3Device.logger
    end
  end

  module S3Accessors
    attr_accessor :s3, :bucket, :key, :object, :metadata

    def s3
      @s3 || AWS::S3.new(http_handler: StatsdHttpHandler.new(AWS.config.http_handler))
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
