pid_file = "/vault/ProjectApi/vault-agent/pidfile"

vault {
  address = "http://vault:8200"
}

auto_auth {
  method {
    type = "approle"
    config = {
      role_id_file_path                   = "/vault/ProjectApi/vault-agent/role-id"
      secret_id_file_path                 = "/vault/ProjectApi/vault-agent/secret-id"
      remove_secret_id_file_after_reading = false
    }
  }

  sink {
    type = "file"

    config = {
      path = "/vault/ProjectApi/vault-agent/token"
    }
  }
}