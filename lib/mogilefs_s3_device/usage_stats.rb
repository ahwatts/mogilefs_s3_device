# -*- encoding: utf-8; -*-

require 'mogilefs_s3_device/controller'

module MogilefsS3Device
  class UsageStats < Controller
    def get
      # Fake usage data.
      usage_data = {
        available: 259056232,
        device: "/dev/mapper/fedora_wingedlizard-home",
        disk: "/home/awatts/rubydev/workspace/shared/mogdata/dev2",
        time: 1410379593,
        total: 399027440,
        use: "36%",
        used: 139969504
      }

      response["Content-Type"] = "text/plain"
      response.body << usage_data.map { |k, v| "#{k}: #{v}" }.join("\n") + "\n"
    end
  end
end
