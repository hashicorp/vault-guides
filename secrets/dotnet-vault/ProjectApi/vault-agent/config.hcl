pid_file = "/ProjectApi/vault-agent/pidfile"

vault {
  address = "http://vault:8200"
}

auto_auth {
  method {
    type = "approle"
    config = {
      role_id_file_path                   = "/ProjectApi/vault-agent/role-id"
      secret_id_file_path                 = "/ProjectApi/vault-agent/secret-id"
      remove_secret_id_file_after_reading = false
    }
  }

  sink {
    type = "file"

    config = {
      path = "/ProjectApi/vault-agent/sink"
    }
  }
}

template {
  source      = "/ProjectApi/vault-agent/appsettings.ctmpl"
  destination = "/ProjectApi/appsettings.json"
}
