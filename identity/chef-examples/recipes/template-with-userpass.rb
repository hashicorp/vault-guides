#
# Cookbook Name:: hashicorp_vault_examples
# Recipe:: default
#

chef_gem 'vault' do
   compile_time true
end

chef_gem 'aws-sdk' do
   compile_time true
end

require 'vault'
require 'aws-sdk'

Vault.address = node['hashicorp_vault_examples']['vault_url']
Vault.auth.userpass(ENV['user'], ENV['password'])
secret = Vault.logical.read("secret/qa/secrets").data

template '/tmp/file.txt' do
  source 'file.txt.erb'
  sensitive true
  variables(
    :db_value => secret[:db_pwd],
    :server_value => secret[:server_pwd],
  )
end
