variable "entities" {
    description = "A set of vault clients to create"
    # Keep nginx as the first vault client for docker-compose demo using AppRole. Please append additional apps to the list
    default = [
        "nginx",
        "app100"
    ]
}

variable "kv_version" {
    description = "The version for the KV secrets engine. Valid values are kv-v2 or kv"
    default = "kv-v2"
}

variable "kv_mount_path" {
    description = "A Path where the KV Secret Engine should be mounted"
    default = "kv"
}

variable "postgres_mount_path" {
    description = "A Path where the Database Secret Engine of type Postgres should be mounted"
    default = "postgres"
}

variable "create_entity_token" {
    description = "Specifies whether a KV read and write policy token should be created"
    default = 1
}

variable "approle_mount_path" {
    description = "A Path where the AppRole Auth Method should be mounted"
    default = "approle"
}

variable "token_ttl" {
    description = "Vault token ttl for KV policies"
    default = "24h"
}

variable "postgres_ttl" {
    description = "# of seconds that postgres credentials should be valid for"
    default = 60
}