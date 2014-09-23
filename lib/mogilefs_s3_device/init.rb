# -*- encoding: utf-8; -*-

require 'rubygems'
require 'bundler/setup'
require 'mogilefs_s3_device'
require 'logger'
require 'aws-sdk'
require 'yaml'

# Utility.
def parse_dsn(dsn)
  puts "dsn = #{dsn.inspect}"
  _, _, opts = dsn.split(":")
  opts = Hash[opts.split(";").map { |o| o.split("=") }]

  rv = {}
  [ :database, :host, :port ].each do |opt|
    if opts[opt.to_s]
      rv[opt] = opts[opt.to_s]
    end
  end

  if rv[:port].to_i > 0
    rv[:port] = rv[:port].to_i
  end

  rv
end

# Set the options for this daemon.
options_file = "/etc/mogilefs/mogilefs_s3_device.yml"
options = {
  "bucket" => "reverbnation-songs-development",
  "prefix" => "mogilefs-backup",
  "log_file" => STDOUT,
}

if File.exist?(options_file)
  File.open(options_file, "rb") { |f| options.merge!(YAML.load(f.read)) }
end

MogilefsS3Device.logger = Logger.new(options["log_file"])
MogilefsS3Device.bucket = options["bucket"]
MogilefsS3Device.prefix = options["prefix"]

# Set the MogileFS database settings from the mogilefs config.
MogilefsS3Device.db_settings = {
  host: "127.0.0.1",
  port: 3306,
  username: ENV['SEC_MOGILEFS_DATABASE_USERNAME'],
  password: ENV['SEC_MOGILEFS_DATABASE_PASSWORD'],
  database: "mogilefs",
  encoding: "utf8",
  reconnect: true,
}

[ "/etc/mogilefs/mogilefs.conf", "/etc/mogilefs/mogilefsd.conf" ].each do |db_settings_file|
  if File.exist?(db_settings_file)
    File.open(db_settings_file, "rb") do |f|
      f.each do |line|
        name = value = nil

        if line =~ /^[^ =]+ *=/
          name, *value = line.split("=")
          name.strip!
          value = value.join("=").strip
        elsif line =~ /^[^ ] +/
          name, value = line.split(" ")
          name.strip!
          value.strip!
        end

        case name
        when "db_dsn"
          MogilefsS3Device.db_settings.merge!(parse_dsn(value))
        when "db_user"
          MogilefsS3Device.db_settings[:username] = value
        when "db_pass"
          MogilefsS3Device.db_settings[:password] = value
        end
      end
    end
    break
  end
end

AWS.config({
    access_key_id: ENV['SEC_MOGILEFS_BACKUP_AMAZON_S3_ACCESS_KEY'],
    secret_access_key: ENV['SEC_MOGILEFS_BACKUP_AMAZON_S3_ACCESS_SECRET_KEY'],
    logger: MogilefsS3Device.logger
  })
