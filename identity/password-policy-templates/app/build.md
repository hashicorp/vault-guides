### Build the basic example application and container (optional)
The basic-example application is available publicly in Dockerhub: [https://hub.docker.com/r/kawsark/vault-example-init/tags](https://hub.docker.com/r/kawsark/vault-example-init/tags). However, most K8S installations will have restrictions regarding approved container registries. The steps below will help compile the application, build the container, then push the application to an approved registry.

#### Install Go runtime and download Vault SDK:
```
# Install Go runtime: 
sudo apt-get install wget -y
wget https://dl.google.com/go/go1.12.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.12.1.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Download the Go SDK for Vault:
go get github.com/hashicorp/vault/api
ls $HOME/go/src/github.com/hashicorp/vault/
```
#### Compile application
```
./build.sh
```
If you do `ls` you will see a `vault-init` executable file which was output from Go compiler. In `Dockerfile` this executable will be added as the Entrypoint: `ENTRYPOINT ["/vault-init"]`

#### Build container and push to container registry
Substitute your `<usermame>` and `<tag>` for command below:
```
docker login
docker build -t <username>/vault-example-init:<tag> .
docker images
docker push <username>/vault-example-init
```