# -*- encoding: utf-8; -*-

require 'aws-sdk'
require 'fileutils'

module MogilefsS3Device
  class S3Proxy
    attr_reader :s3, :bucket, :key, :object, :local_path

    def initialize(request)
      @s3 = AWS::S3.new
      @bucket = @s3.buckets[MogilefsS3Device.bucket]
      @key = MogilefsS3Device.prefix + request.path_info
      @object = @bucket.objects[@key]
      @local_path = File.expand_path("../../../public#{request.path_info}", __FILE__)
    end

    def meta
      if !@tried_object
        begin
          @s3_meta = object.head
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
        if meta.nil?
          not_found(request, response)
        else
          logger.debug("meta = #{meta.inspect}")
          response.status = 200
          response["Content-Type"] = meta[:content_type].to_s
          response["Content-Length"] = meta[:content_length].to_s
          response["Etag"] = meta[:etag].to_s
          response["Last-Modified"] = meta[:last_modified].to_s
          if request.request_method == 'GET'
            response.body = [ object.read ]
          end
        end
      when 'PUT'
        # object.write(request.body.read, content_type: request.content_type)
        # object.write(content_type: request.content_type, content_length: request.content_length.to_i) do |buffer, bytes|
        #   buffer.write(request.body.read(bytes))
        # end
        FileUtils.mkdir_p(File.dirname(@local_path))
        File.open(@local_path, "wb") do |f|
          loop do
            data = request.body.read(8192)
            break if data.nil?
            f.write(data)
          end
        end

        uploader_pid = fork do
          content_type = `file -bi '#{@local_path}'`.chomp
          object.write(@local_path, content_type: content_type)
          File.delete(@local_path)
        end
        Process.detach(uploader_pid)

        response.status = 204
        response.body = []
      when 'DELETE'
        if object.exists?
          object.delete
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
      unless request.request_method == 'HEAD'
        response["Content-Type"] = "text/plain"
        response.body << "This file does not exist.\n"
      end
    end

    def logger
      MogilefsS3Device.logger
    end
  end
end
