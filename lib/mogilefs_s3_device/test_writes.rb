# -*- encoding: utf-8; -*-

require 'ostruct'

module MogilefsS3Device
  class TestWrites
    def initialize
      @writes = {}
    end

    def put_write(path, content_type, body)
      write = OpenStruct.new
      write.content_type = content_type
      write.content = body

      if path =~ /test-write-([0-9]+)$/
        @writes[$1.to_i] = write
      end
    end

    def get_write(path)
      if path =~ /test-write-([0-9]+)$/
        @writes[$1.to_i]
      else
        nil
      end
    end
  end
end
