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

      # Figure out some metadata about the file.
      content_type = `file -bi '#{@local_path}'`.chomp
      domain, mog_key = mogilefs_domain_and_key
      obj_meta =
        if domain && mog_key
          { "mogilefs-domain" => domain,
            "mogilefs-key" => mog_key, }
        else
          {}
        end

      # Now upload it to S3.
      File.open(@local_path, "rb") do |f|
        object.write(f,
          content_type: content_type,
          metadata: obj_meta)
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

    protected

    def mogilefs_domain_and_key
      begin
        conn = MogilefsS3Device.db_conn
        fid = File.basename(request.path_info, ".fid").to_i
        sql = "SELECT f.dkey, d.namespace FROM file f, domain d WHERE d.dmid = f.dmid AND f.fid = #{Mysql2::Client.escape(fid.to_s)}"
        logger.debug("Getting key for fid #{fid.inspect}: #{sql}")
        result = conn.query(sql)
        if result.count >= 1
          [ result.first["namespace"], result.first["dkey"] ]
        else
          [ nil, nil ]
        end
      rescue
        MogilefsS3Device.log_error
        [ nil, nil ]
      end
    end
  end
end
