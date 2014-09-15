# MogilefsS3Device

Turn all of S3 into a device for storing your MogileFS files!

## Installation

Add this line to your application's Gemfile:

    gem 'mogilefs_s3_device'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mogilefs_s3_device

## Usage

To run:

    $ ./bin/mogilefs_s3_device -p 4000

(The cleanup middleware is currently hard-coded to assume that it's
running on port 4000 and set SERVER_PORT to that if it's not
populated.)

## Contributing

1. Fork it ( https://github.com/ahwatts/mogilefs_s3_device/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
