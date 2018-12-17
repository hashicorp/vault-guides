
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

Vault.auth.aws_iam("#{node['hashicorp_vault_examples']['env']}-role", Aws::InstanceProfileCredentials.new, "vault.example.com")
secret = Vault.logical.read("secret/#{node['hashicorp_vault_examples']['env']}/secrets").data

directory "home/#{node['hashicorp_vault_examples']['env']}_user"

user "#{node['hashicorp_vault_examples']['env']}_user" do
  comment 'Vault Test User'
  uid "#{node['hashicorp_vault_examples']['uid']}"
  gid "#{node['hashicorp_vault_examples']['uid']}"
  home "/home/#{node['hashicorp_vault_examples']['env']}_user"
  shell '/bin/bash'
  password secret[:user_pwd]
  sensitive true
end
