#
# Cookbook Name:: hashicorp_vault_examples
# Recipe:: default
#

include_recipe 'hashicorp_vault_examples::execute.rb'
include_recipe 'hashicorp_vault_examples::ssh.rb'
include_recipe 'hashicorp_vault_examples::template.rb'
include_recipe 'hashicorp_vault_examples::user.rb'
include_recipe 'hashicorp_vault_examples::template-with-userpass.rb'
