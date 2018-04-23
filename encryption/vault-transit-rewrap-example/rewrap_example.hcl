path "transit/keys/my_app_key" {
  capabilities = ["read"]
}

path "transit/rewrap/my_app_key" {
  capabilities = ["update"]
}

# This last policy is needed to seed the database as part of the example.
# It can be omitted if seeding is not required
path "transit/encrypt/my_app_key" {
  capabilities = ["update"]
} 
