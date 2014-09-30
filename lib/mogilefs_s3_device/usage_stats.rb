# -*- encoding: utf-8; -*-

require 'mogilefs_s3_device/controller'

module MogilefsS3Device
  class UsageStats < Controller
    def get
      free = MogilefsS3Device.free_space
      total = 100 * free
      used = 99 * free

      # Fake usage data.
      usage_data = {
        time: Time.now.to_i,
        device: "/dev/mapper/fedora_wingedlizard-home",
        disk: "/home/awatts/rubydev/workspace/shared/mogdata/dev2",
        total: total,
        used: used,
        available: free,
        use: "99%",
      }

      response["Content-Type"] = "text/plain"
      text = usage_data.map { |k, v| "#{k}: #{v}" }.join("\n") + "\n"
      response.body << text
    end
  end
end
