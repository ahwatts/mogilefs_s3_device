# -*- encoding: utf-8; -*-

require 'rubygems'
require 'bundler/setup'
require 'mogilefs_s3_device'
require 'logger'
require 'aws-sdk'
require 'yaml'

# Utility.
def parse_dsn(dsn)
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

# Set the default options for this daemon.
options_file = "/etc/mogilefs/mogilefs_s3_device.yml"
options = {
  "bucket" => "reverbnation-songs-development",
  "prefix" => "mogilefs-backup",
  "log_file" => STDOUT,
  "free_space" => (1024**2) * 20, # 20 GiB, in KiB.
  "environment" => "development",
}

# If we're going to be daemonized, don't use stdout as the default log
# destination.
if defined?(::Puma) && Puma.cli_config && Puma.cli_config.options[:daemon]
  options["log_file"] = File.expand_path("../../../log/mogilefs_s3_device.log", __FILE__)
elsif defined?(::Unicorn) && Unicorn::Configurator::RACKUP[:daemonized]
  options["log_file"] = File.expand_path("../../../log/mogilefs_s3_device.log", __FILE__)
end

# Load the config file.
if File.exist?(options_file)
  File.open(options_file, "rb") { |f| options.merge!(YAML.load(f.read)) }
end

# Set the options from the config
MogilefsS3Device.environment = ENV["MFSS3DEVICE_ENV"] || options["environment"] || "development"
MogilefsS3Device.logger = Logger.new(options["log_file"])
MogilefsS3Device.bucket = options["bucket"]
MogilefsS3Device.prefix = options["prefix"]
MogilefsS3Device.free_space = options["free_space"].to_i
MogilefsS3Device.statsd_host = options["statsd_host"]
MogilefsS3Device.statsd_port = options["statsd_port"].to_i
MogilefsS3Device.statsd_prefix = options["statsd_prefix"]

# Configure the logger.
if MogilefsS3Device.environment == "development"
  MogilefsS3Device.logger.level = Logger::DEBUG
else
  MogilefsS3Device.logger.level = Logger::WARN
end

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

# Configure AWS
AWS.config({
    access_key_id: ENV['SEC_MOGILEFS_BACKUP_AWS_ACCESS_KEY_ID'],
    secret_access_key: ENV['SEC_MOGILEFS_BACKUP_AWS_SECRET_ACCESS_KEY'],
    logger: MogilefsS3Device.logger,
  })

# Honeybadger.
begin
  require 'honeybadger'
  Honeybadger.configure do |config|
    config.api_key = ENV['SEC_MOGILEFS_BACKUP_HONEYBADGER_API_KEY']
    config.params_filters << 'RAW_POST_DATA'
    config.development_environments = [ "development", nil ]
    config.logger = MogilefsS3Device.logger
    config.environment_name = MogilefsS3Device.environment
  end
rescue LoadError
  MogilefsS3Device.logger.warn("Honeybadger gem not available, not logging exceptions remotely: #{$!.message}")
end

# Statsd.
begin
  require 'statsd'
  Statsd.logger = MogilefsS3Device.logger
rescue LoadError
  MogilefsS3Device.logger.warn("Statsd-ruby gem not available, not recording stats: #{$!.message}")
end
