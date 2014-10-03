# MogilefsS3Device

Turn all of S3 into a device for storing your MogileFS files!

## Installation

Install it the normal way with:

    $ gem install mogilefs_s3_device

## Usage

First, install your web server of choice. The `mogilefs_s3_device`
binary supports Unicorn and Puma, but is compatible with any
Rack-based server. So:

    $ gem install unicorn

or:

    $ gem install puma

To run:

    $ ./bin/mogilefs_s3_device [unicorn|puma] [unicorn or puma opts]

If you're not using unicorn or puma, you just need to point your
server at the `config.ru` in the Gem installation directory, or write
your own.

MogilefsS3Device pulls the MogileFS database credentials from
`/etc/mogilefs/mogilefs.conf`. It gets its AWS credentials from the
environment variables `SEC_MOGILEFS_BACKUP_AWS_ACCESS_KEY_ID` and
`SEC_MOGILEFS_BACKUP_AWS_SECRET_ACCESS_KEY`.

It reads `/etc/mogilefs/mogilefs_s3_device.yml` for its own config
options:

- `bucket`, `prefix`: The S3 bucket and key prefix with which to store
  the files on S3.

- `log_file`: The file to which to send the logs to. Defaults to
  STDOUT if not daemonized, `log/mogilefs_s3_device.log` if
  daemonized.

- `free_space`: How much free space to report back to the MogileFS
  tracker. Regardless of the setting here, the device will appear to
  the tracker to be 99% full (therefore the used space will be 9 times
  this number). Obviously these numbers are totally fake, as used and
  free space aren't really things on S3, but in order to discourage
  the trackers from putting files on this device, we make it look
  full.

## Contributing

1. Fork it ( https://github.com/ahwatts/mogilefs_s3_device/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
