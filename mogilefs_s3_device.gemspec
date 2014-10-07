# -*- mode: ruby; encoding: utf-8; -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mogilefs_s3_device/version'

Gem::Specification.new do |spec|
  spec.name          = "mogilefs_s3_device"
  spec.version       = MogilefsS3Device::VERSION
  spec.authors       = ["Andrew Watts"]
  spec.email         = ["ahwatts@gmail.com"]
  spec.summary       = %q{Runs a server implementing webdav, but storing the files on S3.}
  spec.description   = %q{Runs a server implementing webdav, but storing the files on S3.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk", "~> 1.54"
  spec.add_dependency "connection_pool"
  spec.add_dependency "mysql2"
  spec.add_dependency "rack"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "gemfury"
end
