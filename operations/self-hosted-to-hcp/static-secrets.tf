#------------------------------------------------------------------------
# Vault Learn lab: Self-hosted to HCP - Static secrets
#------------------------------------------------------------------------

# Provision some static secrets in the KV secrets engine at the path 'kv-v2'

resource "vault_generic_secret" "api-wizard-service" {
  path = "api-credentials/admin/api-wizard"

  data_json = <<EOT
{
  "api-client-key": "api-eyj2LqNPIlgk7M616Tg",
  "api-secret-key": "V9QZ8l6xzhZGkq8jsUjpwvRMIWLRIMGWgnNqSWwT0gU2"
}
EOT
  depends_on = [
    vault_mount.kv-v2
  ]
}

resource "vault_generic_secret" "student_api_key" {
  path = "api-credentials/student/api-key"

  data_json = <<EOT
{
  "api_key":   "A26nYsDuB3Y9GHx2mstmuaPAQJPQjYtE2s5kEsIQ9Nk"
}
EOT
  depends_on = [
    vault_mount.kv-v2
  ]
}

resource "vault_generic_secret" "golden" {
  path = "api-credentials/student/golden"

  data_json = <<EOT
{
  "egg-b64":   "CiAgICAgICAgICAgICAgICAgICAuICAgICAgICAuICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAnL3ltcyAgICAgICAgeW15LycgICAgICAgICAgICAgICAKICAgICAgICAgICAgLW9oSEhISHMgICAgICAgIHlISEhIaG8nICAgICAgICAgICAgCiAgICAgICAgJy9zbUhISEhISEhzICAgICAgICB5SEhISEhILiAgLScgICAgICAgIAogICAgIC0raEhISEhISEhISEhtKyAgICAgICAgeUhISEhISC4gIHNIaCstICAgICAKICAgK21ISEhISEhISEhIaCstICAgICAgICAgIHlISEhISEguICBzSEhISG0rICAgCiAgIHlISEhISEhIZHM6JyAgIC4tICAgICAgICB5SEhISEhILiAgc0hISEhIeSAgIAogICB5SEhISEhoLiAgICc6c2RIeSAgICAgICAgeUhISEhISC4gIHNISEhISHkgICAKICAgeUhISEhIcyAgLmhISEhISHkgICAgICAgIHlISEhISEguICBzSEhISEh5ICAgCiAgIHlISEhISHMgIC5ISEhISEh5ICAgICAgICB5SEhISEhILiAgc0hISEhIeSAgIAogICB5SEhISEhzICAuSEhISEhIbXl5eXl5eXl5bUhISEhISC4gIHNISEhISHkgICAKICAgeUhISEhIcyAgLkhISEhISEhISEhISEhISEhISEhISEguICBzSEhISEh5ICAgCiAgIHlISEhISHMgIC5ISEhISEhISEhISEhISEhISEhISEhILiAgc0hISEhIeSAgIAogICB5SEhISEhzICAuSEhISEhIbXl5eXl5eXl5bUhISEhISC4gIHNISEhISHkgICAKICAgeUhISEhIcyAgLkhISEhISHkgICAgICAgIHlISEhISEguICBzSEhISEh5ICAgCiAgIHlISEhISHMgIC5ISEhISEh5ICAgICAgICB5SEhISEhoJyAgc0hISEhIeSAgIAogICB5SEhISEhzICAuSEhISEhIeSAgICAgICAgeUhkbzonICAgLmhISEhISHkgICAKICAgeUhISEhIcyAgLkhISEhISHkgICAgICAgIC0uICAgJy9zbUhISEhISEh5ICAgCiAgICtkSEhISHMgIC5ISEhISEh5ICAgICAgICAgIC1vaEhISEhISEhISEhkKyAgIAogICAgIC4raEhzICAuSEhISEhIeSAgICAgICAgb21ISEhISEhISEhIaCsuICAgICAKICAgICAgICAnLiAgLkhISEhISHkgICAgICAgIHlISEhISEhIbXM6JyAgICAgICAgCiAgICAgICAgICAgICcraEhISEh5ICAgICAgICB5SEhISGgrLSAgICAgICAgICAgIAogICAgICAgICAgICAgICAnYmxzfCAgICAgICAgeUhkLycgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgIC4gICAgICAgIC4K"
}
EOT
  depends_on = [
    vault_mount.kv-v2
  ]
}

