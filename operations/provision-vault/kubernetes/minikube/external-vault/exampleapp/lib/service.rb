require "sinatra"
require "faraday"
require "json"
require "logger"

$stdout.sync = true

class ExampleApp < Sinatra::Base

  set :port, ENV['SERVICE_PORT'] || "8080"
  set :vault_token, ENV["VAULT_TOKEN"] || "root"

  configure :development do
    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    set :raise_errors, true
    set :logger, logger
    set :vault_url, ENV["VAULT_ADDR"] || "http://host.docker.internal:8200"
  end

  configure :production do
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    set :vault_url, ENV["VAULT_ADDR"] || "http://vault:8200"
  end

  # GET "/"
  get "/" do
    logger.info "Received Request."

    # Set up an undefined state and set the vault server and secrets path
    secrets = { "username" => "undefined", "password" => "undefined" }

    secrets_path = "secret/data/devwebapp/config"

    # Ask for the secret at the path
    vault_response = Faraday.get "#{settings.vault_url}/v1/#{secrets_path}" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-Vault-Token'] = settings.vault_token
    end

    if vault_response.status != 200
      raise Exception.new "The secret request failed: #{vault_response.body}"
    end

    # Parse the JSON
    content = JSON.parse(vault_response.body) rescue {}

    # Traverse the response to find the secrets in the response
    if content.key?('data') and content['data'].key?('data')
      secrets = content['data']['data']
    end

    # Return secret
    secrets.to_s
  end

end