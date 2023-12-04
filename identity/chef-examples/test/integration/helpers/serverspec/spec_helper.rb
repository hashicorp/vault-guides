# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require 'serverspec'

if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil?
  set :backend, :exec
else
  set :backend, :cmd
  set :os, family: 'windows'
end
