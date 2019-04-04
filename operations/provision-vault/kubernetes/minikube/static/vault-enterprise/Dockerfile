FROM vault:latest
MAINTAINER Joe ImageBuilder <joe@exampleorg.example>

LABEL upstream_vendor="HashiCorp, Inc." \
      upstream_contact="https://hashicorp.com" \
      repo="https://github.com/exampleorg/docker-vault-enterprise" \
      vendor="Joe DockerBuilder" \
      contact="joe@exampleorg.example"

# Vault Enterprise binary has been pre-populated here.
COPY assets/binaries/vault /bin/vault

CMD ["server", "-config", "/vault/config"]

COPY Dockerfile /Dockerfile
