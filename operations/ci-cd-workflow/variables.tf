# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "address" {
  description = "Origin URL of the Vault server. This is a URL with a scheme, a hostname and a port but with no path. May be set via the VAULT_ADDR environment variable"
}

variable "token" {
  description = "Vault token that will be used by Terraform to authenticate. May be set via the VAULT_TOKEN environment variable. If none is otherwise supplied, Terraform will attempt to read it from ~/.vault-token (where the vault command stores its current token). Terraform will issue itself a new token that is a child of the one given, with a short TTL to limit the exposure of any requested secrets. Note that the given token must have the update capability on the auth/token/create path in Vault in order to create child tokens"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# You can provide a value for each of these parameters as needed.
# ---------------------------------------------------------------------------------------------------------------------

variable "enabled_auth_methods" {
  description = "Authentication methods enabled"
  type        = "list"
  default     = ["approle", "github"]
}

variable "db_connection_string" {
  description = "Connection string for database secret engine"
  default     = "postgres://USERNAME:PASSWORD@URL"
}

#variable "ca_cert_file" {
#  description = "Path to a file on local disk that will be used to validate the certificate presented by the Vault server. May be set via the VAULT_CACERT environment variable"
#}


#variable "ca_cert_dir" {
#  description = "Path to a directory on local disk that contains one or more certificate files that will be used to validate the certificate presented by the Vault server. May be set via the VAULT_CAPATH environment variable"
#}


#variable "client_auth" {
#  description = "A configuration block, described below, that provides credentials used by Terraform to authenticate with the Vault server. At present there is little reason to set this, because Terraform does not support the TLS certificate authentication mechanism"
#}


# variable "skip_tls_verify" {
#   description = "Set this to true to disable verification of the Vault server's TLS certificate. This is strongly discouraged except in prototype or development environments, since it exposes the possibility that Terraform can be tricked into writing secrets to a server controlled by an intruder. May be set via the VAULT_SKIP_VERIFY environment variable"
# }


# variable "max_lease_ttl_seconds" {
#   description = "Used as the duration for the intermediate Vault token Terraform issues itself, which in turn limits the duration of secret leases issued by Vault. Defaults to 20 minutes and may be set via the TERRAFORM_VAULT_MAX_TTL environment variable. See the section above on Using Vault credentials in Terraform configuration for the implications of this setting."
# }

