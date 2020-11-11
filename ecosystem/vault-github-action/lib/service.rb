require "sinatra"
require "faraday"
require "json"
require "logger"

$stdout.sync = true

class ExampleApp < Sinatra::Base

  set :port, ENV['SERVICE_PORT'] || "8080"

  configure :development do
    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG

    set :raise_errors, true
    set :logger, logger

    set :app_secret, File.read('app_secret')
  end

  configure :production do
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    set :app_secret, File.read('app_secret')
  end

  # GET "/"
  get "/" do
     # Return secret
    "#{app_secret.to_s}\n"
  end
end