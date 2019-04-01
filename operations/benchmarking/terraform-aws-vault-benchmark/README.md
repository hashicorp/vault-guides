# terraform-aws-vault-benchmark

## Disclaimer
This repo is intended to provide guidance and will not be officially maintained by HashiCorp.

## Overview
This repo sets up a Vault cluster in AWS that reflects our [reference architecture](https://learn.hashicorp.com/vault/operations/ops-reference-architecture).  The goal of this repo is to provide a batteries included Terraform environment to capture key performance metrics and telemetry when benchmarking Vault.

This environment contains the following servers:
* 1x Bastion
* 3x Vault
* 3x Consul
* 1x Envoy
* 1x Telemetry
* 1x Benchmark

## Architecture
This environment is compatible with Ubuntu based images from our [guides configuration](https://github.com/hashicorp/guides-configuration), where the bulk of provisioning is done. The [templates](terraform/templates) folder contains our last mile provisioning to set up our Envoy configuration and lay down the telemetry collection via cloud-init.

An Envoy proxy fronts the Vault deployment and actively checks for either primary or performance standby return codes. With Envoy as a front proxy we have great observability into how our test is performing in realtime. Envoy also allows us to leverage HTTP2 and efficiently multiplex connections to our Vault upstreams.  Envoy has both http and https listeners for clients. Additionally, there is an NLB in front of Envoy to support WAN testing.

Vault and Consul are set up in the standard 3x node pattern. TLS is enabled on the Vault servers.  Vault is configured for auto unseal with KMS.  Storage for both Vault & Consul uses [Burstable gp2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSVolumeTypes.html#EBSVolumeTypes_gp2) to control cost. Depending on the workload you are testing you may want to change to  [Provisioned IOPS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSVolumeTypes.html#EBSVolumeTypes_piops), which are dedicated, but expensive.

## Setting up the Environment
You can find the terraform files in the [terraform folder](terraform). An example [variable file](terraform/terraform.tfvars.example) is included. You will need to provide both [Consul](https://github.com/hashicorp/guides-configuration/tree/master/consul) & [Vault](https://github.com/hashicorp/guides-configuration/tree/master/vault) AMIs from your account to Terraform.

Vault is not initialized by default. You can follow the [getting started guide](https://learn.hashicorp.com/vault/getting-started/deploy#initializing-the-vault) to initialize your Vault. You can get the CA for both Vault & Envoy certificates with `terraform output ca`. The CA is trusted on the Benchmark server, the Envoy server, and the Vault servers.

You can access the environment through the bastion host. You can get the bastion host endpoint as a `terraform output bastion`. Terraform will provide the private key file in the directory. If you delete your key you can retrieve it again with `terraform output key`. You can run `consul members` from the bastion host to list all servers, and ssh to any server with agent forwarding enabled.

```
$ ssh-add *.pem
$ ssh -A ubuntu@$(terraform output bastion)
```

## Running a Benchmark
This repo is designed to work with the following tools:
* https://github.com/wg/wrk
* https://github.com/giltene/wrk2

More detailed test scripts can be found [here](../wrk-core-vault-operations).

Depending on the level of concurrency you use you may need to adjust the **ulimit** when running wrk/wrk2 on either the benchmark server or your remote machine. Using both of these tools together can provide a holistic assessment of both stress and load capabilities of your cluster.

These tools are downloaded and installed for you on the benchmark server. For best results you should test from within the LAN (the benchmark server) but there is an NLB in place if you so chose to run remotely and test over a WAN. You can get the NLB endpoint as a `terraform output envoy_http` or `terraform output envoy_https`.

Below are examples of a valid wrk/wrk2 tests that you could run from the benchmark server. This test is simple and would read a KV entry from Vault. We've given Envoy a static private IP but you could also resolve it with Consul DNS.

10k concurrent connections for 5 minutes for max RPS & 10s timeout & latency stats.<br/>
`wrk -t4 -c10000 -d300s --latency  --timeout 10s --header 'X-VAULT-TOKEN: <token>'  'https://10.0.1.20:8443/v1/secret/foo'`

10k concurrent connections for 5 minutes for 5k target RPS & 10s timeout & latency stats.<br/>
`wrk2 -t4 -R5000 -c10000 -d300s --latency  --timeout 10s --header 'X-VAULT-TOKEN: <token>'  'https://10.0.1.20:8443/v1/secret/foo'`


## Monitoring a Benchmark
Monitoring dashboards are included for you in the [grafana](grafana) folder. These dashboards are based on the following:
* [HashiCorp Vault Monitoring Guide](https://learn.hashicorp.com/vault/operations/monitoring)
* [Transferwise's Envoy Dashboards based on Lyft's Dashboards](https://github.com/transferwise/prometheus-envoy-dashboards)

Read the following to import the dashboards into Grafana: http://docs.grafana.org/reference/export_import/

You can get the Grafana endpoint as a `terraform output grafana`. The default username/password is admin/admin.

Your dashboards should look like the following during your tests:

*Vault*
![Alt text](samples/vault.png?raw=true "Vault Monitoring")

*Consul*
![Alt text](samples/consul.png?raw=true "Consul Monitoring")

*Envoy*
![Alt text](samples/ingress.png?raw=true "Envoy Monitoring")

## TO DOs
* Consolidate monitoring to either Prometheus or InfluxDB
* Add RHEL support
