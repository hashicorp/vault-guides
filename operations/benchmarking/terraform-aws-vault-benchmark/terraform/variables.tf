variable "owner" {
}

variable "ttl" {
}

variable "env" {
}

variable "azs" {
  type = list(string)
}

variable "region" {
}

variable "consul_ami" {
}

variable "vault_ami" {
}

variable "vault_instance_type" {
  description = "Vault servers, shipping metrics with Telegraf agent"
  # default = "m5.2xlarge"
}

variable "consul_instance_type" {
  description = "Consul servers, shipping metrics with Telegraf agent"
  # default = "m5.4xlarge"
}

variable "telemetry_instance_type" {
  description = "Instance receiving the metrics, with InfluxDB and Graphana"
  # default = "m5.2xlarge"
}

variable "benchmark_instance_type" {
  description = "Instance that will run the wrk tests"
  # default = "m5.2xlarge"
}

variable "envoy_instance_type" {
  description = "Envoy server, for additional obervability metrics"
  # default = "m5.2xlarge"
}

variable "consul_cluster_size" {
  default = "3"
}

variable "vault_ips" {
  default = {
    "0" = "10.0.1.15"
    "1" = "10.0.2.16"
    "2" = "10.0.3.17"
  }
}

