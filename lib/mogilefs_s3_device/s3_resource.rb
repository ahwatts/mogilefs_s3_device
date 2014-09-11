# -*- encoding: utf-8; -*-

require 'dav4rack'
require 'pry'
require 'aws-sdk'
require 'ostruct'

module MogilefsS3Device
  class S3Resource < DAV4Rack::Resource
    include DAV4Rack::HTTPStatus

    def setup
      logger.debug("Setting up resource: method = #{request.env['REQUEST_METHOD']} path = #{path}")
    end

    # S3 accessors.

    def s3
      @s3 ||= AWS::S3.new
    end

    def bucket
      @bucket ||= s3.buckets[MogilefsS3Device.bucket]
    end

    def s3_key
      @key ||= MogilefsS3Device.prefix + path
    end

    def object
      @object ||= bucket.objects[s3_key]
    end

    def object_metadata
      @object_md ||=
        begin
          object.head
        rescue AWS::S3::Errors::NoSuchKey
          nil
        end
    end

    # Methods describing this resource.

    def collection?
      is_known_directory?
    end

    def content_length
      object_metadata.content_length
    end

    def content_type
      object_metadata.content_type
    end

    def creation_date
      object_metadata.last_modified
    end

    def etag
      object_metadata.etag
    end

    def last_modified
      object_metadata.last_modified
    end

    def exist?
      if is_known_directory?
        true
      else
        !object_metadata.nil?
      end
    end

    # Actions on this resource.

    def get(request, response)
      if collection?
        OK
      elsif exist?
        response.body << object.read
        OK
      else
        NotFound
      end
    end

    def put(request, response)
      object.write(request.body.read)
      Created
    end

    def make_collection
      if is_known_directory?
        Created
      elsif exist?
        BadRequest
      else
        Forbidden
      end
    end

    def delete
      if collection?
        BadRequest
      elsif exist?
        object.delete
        NoContent
      else
        NotFound
      end
    end

    protected

    def logger
      MogilefsS3Device.logger
    end

    def is_known_directory?
      [ /^\/$/, /^\/dev[0-9]+$/, /^\/dev[0-9]+\/test-write$/, /^\/dev[0-9]+\/(?:[0-9]+\/)*[0-9]+\/?$/ ].any? do |pt|
        path =~ pt
      end
    end
  end
end
