require "sinatra"
require "faraday"
require "json"
require "logger"

$stdout.sync = true

class ExampleApp < Sinatra::Base

  configure :development, :production do
    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG if development?
    set :logger, logger
  end

  # GET "/"
  get "/" do
    logger.info "Received Request - Port forwarding is working."

    # Set up an undefined state and set the vault server and secrets path
    secrets = { "username" => "undefined", "password" => "undefined" }
    vault_url = ENV["VAULT_ADDR"]

    logger.info "Received Request - Port forwarding is working."

    jwt = File.read ENV["JWT_PATH"]

    logger.info "Read JWT: [#{jwt}]"

    auth_path = "auth/kubernetes/login"

    login_response = Faraday.put "#{vault_url}/v1/#{auth_path}" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = { "role" => "exampleapp", "jwt" => jwt }.to_json
    end

    vault_token = JSON.parse(login_response.body)["auth"]["client_token"]
    logger.info "Received Vault Token: [#{vault_token}]"

    secrets_path = "secret/data/exampleapp/config"

    # Setup a connection the vault server
    vault_response = Faraday.get "#{vault_url}/v1/#{secrets_path}" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-Vault-Token'] = vault_token
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