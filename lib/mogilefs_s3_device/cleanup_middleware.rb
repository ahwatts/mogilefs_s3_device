# -*- encoding: utf-8; -*-

module MogilefsS3Device
  class Cleanup
    def initialize(app)
      @app = app
    end

    def call(env)
      if env['SERVER_PORT'].nil?
        env['SERVER_PORT'] = "4000"
      end
      # logger.debug("#{env['REQUEST_METHOD'].inspect} #{env['PATH_INFO'].inspect}")
      @app.call(env)
    end

    def logger
      MogilefsS3Device.logger
    end
  end
end
