# Grant 'create', 'read' and 'update' permission to paths prefixed by 'secret/data/test/'
path "secret/data/test/*" {
  capabilities = [ "create", "read", "update" ]
}

# Manage namespaces
path "sys/namespaces/*" {
   capabilities = [ "create", "read", "update", "delete", "list" ]
}
