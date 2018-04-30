FROM consul:latest
MAINTAINER Joe ImageBuilder <joe@exampleorg.example>

LABEL upstream_vendor="HashiCorp, Inc." \
      upstream_contact="https://hashicorp.com" \
      repo="https://github.com/exampleorg/docker-consul-enterprise" \
      vendor="Joe DockerBuilder" \
      contact="joe@exampleorg.example"

# Consul Enterprise binary has been pre-populated here.
COPY assets/binaries/consul /bin/consul

COPY Dockerfile /Dockerfile
