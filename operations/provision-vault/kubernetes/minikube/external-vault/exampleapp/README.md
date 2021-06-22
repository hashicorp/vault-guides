# Exampleapp in Ruby

## Local Development

This application is built to run in a cluster and not locally. It would take
some additional changes to have it work locally.

```shell
$ bundle install
$ rackup
```

## Docker Image

Create the Docker image.

```shell
$ docker build . -t USERNAME/devwebapp-ruby:k8s
```

Test the Docker image with a Vault server running locally

```shell
$ docker run -it -p 8080:8080 --env VAULT_ADDR=http://host.docker.internal:8200 USERNAME/devwebapp-ruby:k8s
```

Push the Docker image.

```shell
$ docker push USERNAME/devwebapp-ruby:k8s
```
