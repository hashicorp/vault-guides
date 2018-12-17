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

# Add a second authorized_hosts file to sshd_config.  This allows us to add the jenkins file without
# Needing to override the existing keys
cookbook_file '/etc/ssh/sshd_config' do
  source 'sshd_config'
  action :create
end

# Restart sshd only if the hosts file was updated.
service 'sshd' do
  subscribes :restart, 'cookbook_file[/etc/ssh/sshd_config]', :immediately
end

# Get the key from Vault
Vault.address = node['hashicorp_vault_examples']['vault_url']
Vault.auth.aws_iam("#{node['hashicorp_vault_examples']['env']}-role", Aws::InstanceProfileCredentials.new, "vault.example.com")
secret = Vault.logical.read("secret/#{node['hashicorp_vault_examples']['env']}/secrets").data

file "/home/ec2-user/.ssh/authorized_keys.jenkins" do
  content secret[:vault_test_ssh]
  group 'ec2-user'
  owner 'ec2-user'
  mode '644'
  sensitive true
end
