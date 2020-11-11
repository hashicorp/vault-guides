# Exampleapp in Ruby

These assets are provided to perform the tasks described in the [Vault GitHub
Action](https://learn.hashicorp.com/tutorials/vault/github-actions) tutorial.

## Docker Image

Create a Docker image for the application and label it
`vault-action-exampleapp`.

```shell
$ docker build . --file Dockerfile -t vault-action-exampleapp
```

View the contents of the app_secret file in the Docker image.

```shell
$ docker run vault-action-exampleapp /bin/bash -c "cat ./app_secret"
```

Create a Docker image for the application and label it
`vault-action-exampleapp` and override the secret.

```shell
$ docker build . --file Dockerfile --build-arg app_secret="SECRET_OVERRIDE" -t vault-action-exampleapp
```
