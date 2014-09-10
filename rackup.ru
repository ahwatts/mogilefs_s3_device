# -*- mode: ruby; encoding: utf-8; -*-

# $LOAD_PATH << File.expand_path("../lib", __FILE__)
require 'dav4rack'

use Rack::Lint
use Rack::Logger, Logger::DEBUG
use Rack::CommonLogger
run DAV4Rack::Handler.new(:root => File.expand_path("../public", __FILE__))
