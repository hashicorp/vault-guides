# Uncomment this to have Agent run once (e.g. when running as an initContainer)
# exit_after_auth = true
pid_file = "/home/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes"
        config = {
            role = "example"
        }
    }

    sink "file" {
        config = {
            path = "/home/vault/.vault-token"
        }
    }
}

vault {
  address = "http://192.168.64.1:8200"
}

template {
  source      = "/home/vault/customer.tmpl"
  destination = "/home/vault/customer.txt"
}
