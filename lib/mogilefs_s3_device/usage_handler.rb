# -*- encoding: utf-8; -*-

require 'logger'

module MogilefsS3Device
  class UsageHandler
    def initialize(app)
      @app = app
    end

    def logger
      if @logger
        @logger
      else
        Logger.new("/dev/null")
      end
    end

    def call(env)
      @logger ||= env["rack.logger"]

      if env["PATH_INFO"] =~ /^\/+dev[0-9]+\/usage/
        # Fake data.
        usage_data = {
          available: 259056232,
          device: "/dev/mapper/fedora_wingedlizard-home",
          disk: "/home/awatts/rubydev/workspace/shared/mogdata/dev2",
          time: 1410379593,
          total: 399027440,
          use: "36%",
          used: 139969504
        }

        [ 200, { "Content-Type" => "text/html" }, [ usage_data.map { |k, v| "#{k}: #{v}" }.join("\n") + "\n" ] ]
      else
        @app.call(env)
      end
    end
  end
end
