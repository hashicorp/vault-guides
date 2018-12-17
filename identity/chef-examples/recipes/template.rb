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

# Authentication is based on the AWS instance IAM profile role
Vault.auth.aws_iam("#{node['hashicorp_vault_examples']['env']}-role", Aws::InstanceProfileCredentials.new, "vault.example.com")

#Read datastructure with secrets
secret = Vault.logical.read("secret/#{node['hashicorp_vault_examples']['env']}/secrets").data

template '/tmp/file.txt' do
  source 'file.txt.erb'
  sensitive true
  variables(
    :db_value => secret[:db_pwd],
    :server_value => secret[:server_pwd],
  )
end
