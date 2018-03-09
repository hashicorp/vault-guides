#
# Cookbook:: vault_chef_approle_demo
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

# Vault Ruby client: https://github.com/hashicorp/vault-ruby
chef_gem 'vault' do
  compile_time true
end

require 'vault'

# Wait for Terraform user_data to finish
# https://github.com/hashicorp/terraform/issues/4668
ruby_block 'wait for user_data' do
  block do
    true until ::File.exists?('/tmp/signal')
  end
end

# Install Nginx
execute "apt-get update" do
  command "apt-get update"
end

package 'nginx' do
  action :install
end

service 'nginx' do
  action [ :enable, :start ]
end

# Configure address for Vault Gem
Vault.address = ENV['VAULT_ADDR']

# Get AppRole RoleID from our environment variables (delivered via Terraform)
var_role_id = ENV['APPROLE_ROLEID']

# Get Vault token from data bag (used to retrieve the SecretID)
vault_token_data = data_bag_item('secretid-token', 'approle-secretid-token')

# Set Vault token (used to retrieve the SecretID)
Vault.token = vault_token_data['auth']['client_token']

# Get AppRole SecretID from Vault
var_secret_id = Vault.approle.create_secret_id('app-1').data[:secret_id]

# Combine RoleID and SecretID together for AppRole authentication
secret = Vault.auth.approle( var_role_id, var_secret_id )

# Save the AppRole authentication token so we can output it in our template
var_approle_token = secret.auth.client_token

# Read our secrets
var_secrets = Vault.logical.read("secret/app-1")

# Output our info
template '/var/www/html/index.html' do
  source 'index.html.erb'
  variables(
    :role_id => var_role_id,
    :secret_id => var_secret_id,
    :approle_token => var_approle_token,
    :app_1_secrets => var_secrets.data
  )
end
