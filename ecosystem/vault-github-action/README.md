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
$ docker build . -t exampleapp-ruby
```

Test the Docker image.

```shell
$ docker run -it -p 8080:8080 exampleapp-ruby:k8s
```

Push the Docker image.

```shell
$ docker push USERNAME/exampleapp-ruby:k8s
```

## Load it into Kubernetes

The assumption is Kubernetes, Vault, and Consul are configured correctly.

Update the configuration file to use your Docker image.

Apply the configuration that describes the exampleapp-simple pod.

```shell
$ kubectl apply -f exampleapp.yaml
```

Check the logs of the server.

```shell
$ kubectl logs exampleapp-simple-c54944b4c-pjqlc
```

Login to the instance.

```shell
$ kubectl exec -it exampleapp-simple-c54944b4c-pjqlc /bin/bash
```
