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

    set :jwt_path, nil
    set :vault_url, ENV["VAULT_ADDR"] || "http://localhost:8200"
  end

  configure :production do
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    set :jwt_path, ENV["JWT_PATH"]
    set :vault_url, ENV["VAULT_ADDR"] || "http://vault:8200"
  end

  # GET "/"
  get "/" do
    logger.info "Received Request - Port forwarding is working."

    # Set up an undefined state and set the vault server and secrets path
    secrets = { "username" => "undefined", "password" => "undefined" }
    vault_token = "root"

    logger.info "Received Request - Port forwarding is working."

    if settings.jwt_path
      jwt = File.read settings.jwt_path

      logger.info "Read JWT: [#{jwt}]"

      auth_path = "auth/kubernetes/login"

      login_response = Faraday.put "#{settings.vault_url}/v1/#{auth_path}" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = { "role" => "exampleapp", "jwt" => jwt }.to_json
      end

      vault_token = JSON.parse(login_response.body)["auth"]["client_token"]
      logger.info "Received Vault Token: [#{vault_token}]"
    end

    if vault_token.nil?
      raise Exception.new "The vault token failed to be set during login"
    end

    secrets_path = "secret/data/exampleapp/config"

    # Ask for the secret at the path
    vault_response = Faraday.get "#{settings.vault_url}/v1/#{secrets_path}" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-Vault-Token'] = vault_token
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