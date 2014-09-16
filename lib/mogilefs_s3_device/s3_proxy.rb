# -*- encoding: utf-8; -*-

require 'aws-sdk'
require 'fileutils'
require 'mogilefs_s3_device/controller'
require 'mogilefs_s3_device/s3_accessors'

module MogilefsS3Device
  class S3Proxy < Controller
    include S3Accessors

    def initialize(env)
      super(env)
      @key = MogilefsS3Device.prefix + request.path_info
      # @local_path = File.expand_path("../../../public#{request.path_info}", __FILE__)
      @local_path = File.join("/tmp/mogilefs_s3_device", request.path_info)
    end

    def get
      if metadata.nil?
        not_found
      else
        respond_with_object(request, response)
      end
    end
    alias_method :head, :get

    def put
      # object.write(request.body.read, content_type: request.content_type)
      # object.write(content_type: request.content_type, content_length: request.content_length.to_i) do |buffer, bytes|
      #   buffer.write(request.body.read(bytes))
      # end

      # Buffer the file to disk so we can get a proper content-type
      # for it and so that we're not buffering the whole file in to
      # memory.
      FileUtils.mkdir_p(File.dirname(@local_path))
      File.open(@local_path, "wb") do |f|
        loop do
          data = request.body.read(8192)
          break if data.nil?
          f.write(data)
        end
      end

      # Now upload it to S3.
      content_type = `file -bi '#{@local_path}'`.chomp
      File.open(@local_path, "rb") do |f|
        object.write(f, content_type: content_type)
      end
      File.delete(@local_path)

      no_content
    end

    def delete
      if object.exists?
        object.delete
        no_content
      else
        not_found
      end
    end

    def mkcol
      bad_request
    end
  end
end
