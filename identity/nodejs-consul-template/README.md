This project is a secure intro workflow using consul-template.

Instructions for use:

1. Configure Vault with `vagrant up vault`.
2. Configure Nodejs with `vagrant up nodejs`.
3. SSH to the Nodejs server with `vagrant ssh nodejs` and check the express server on localhost:3000. You'll see the Vault secret.
