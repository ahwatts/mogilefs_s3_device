# -*- encoding: utf-8; -*-

module MogilefsS3Device
  class Cleanup
    def initialize(app)
      @app = app
    end

    def call(env)
      if env['SERVER_PORT'].nil?
        env['SERVER_PORT'] = 4000
      end
      @app.call(env)
    end
  end
end
