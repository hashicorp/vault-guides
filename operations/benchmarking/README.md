# Vault Benchmarking

## Disclaimer
This repo is intended to provide guidance and will not be officially maintained by HashiCorp.

## Overview
This directory contains two sub-directories that can be used to run Vault benchmarks:
* [terraform-aws-vault-benchmark](./terraform-aws-vault-benchmark) contains Terraform code to provision a Vault cluster in AWS that can be used to run benchmarks. This was written by Lance Larsen.
* [wrk-core-vault-operations](./wrk-core-vault-operations) contains Lua benchmark scripts. These were mostly written by Roger Berlind who drew inspiration from Jacob Friedman. Kawsar Kamal added the authenticate.lua script to support Vault batch tokens.
