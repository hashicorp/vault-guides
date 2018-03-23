# Introduction

The goal of this document is to provide guidance in the setup,
administration, and operation of various components of the HashiStack
when running on or integrating with the
[Kubernetes](https://kubernetes.io) cluster management framework.

The document assumes Enterprise offerings of the various HashiStack
tools however much of the guidance is consistent for OSS offerings of
HashiCorp tooling though with reduced functionality for scaling, DR, and
collaboration features.

This is a living document and, over time, will expand to include
additional scenarios and use-cases. See the table below for more
information.

## Scenarios and Use-Cases

<table>
<thead>
<tr class="header">
<th>desc</th>
<th>environments</th>
<th>network</th>
<th>storage</th>
<th>priority</th>
<th>status</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>on-cluster Consul + on-cluster Vault w/ overlay + persistent storage serving on-cluster workloads</td>
<td>minikube, GCP GKE</td>
<td>underlay/overlay</td>
<td>+ persistent volumes</td>
<td>high</td>
<td>draft - beta</td>
</tr>
</tbody>
</table>

## Future Scenarios and Use-Cases

<table>
<thead>
<tr class="header">
<th>desc</th>
<th>environments</th>
<th>network</th>
<th>storage</th>
<th>priority</th>
<th>status</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>on-cluster Consul + on-cluster Vault providing services to off-cluster workloads</td>
<td>on-prem</td>
<td>Calico w/ IPIP Encap</td>
<td>+ persistent volumes</td>
<td>medium</td>
<td>not yet started</td>
</tr>
<tr class="even">
<td>on-cluster Consul + on-cluster Vault on Azure</td>
<td>MS Azure EKS</td>
<td>??</td>
<td>+ persistent volumes</td>
<td>medium</td>
<td>not yet started</td>
</tr>
<tr class="odd">
<td>on-cluster Consul + on-cluster Vault on AWS EKS</td>
<td>AWS EKS</td>
<td>??</td>
<td>+ persistent volumes</td>
<td>low</td>
<td>not yet started</td>
</tr>
</tbody>
</table>

# Prerequisites

## Docker images for HashiCorp Enterprise offerings

HashiCorp currently provides [Docker Hub](https://hub.docker.com) images
for only the OSS versions of the various HashiCorp products.

  - [Packer OSS](https://hub.docker.com/r/hashicorp/packer)
  - [Terraform OSS](https://hub.docker.com/r/hashicorp/terraform)
  - [Consul OSS](https://hub.docker.com/_/consul/)
  - [Vault OSS](https://hub.docker.com/_/vault)

Note that [Nomad](https://nomadproject.io) is not offered as a container
image as Nomad is often used as a container scheduler and, [some clever
presentations](https://www.youtube.com/watch?v=v77FFbQwC6E) and either
Docker-in-Docker or clever domain socket mounting aside,
Nomad-as-a-container is arguably not a great deployment scenario.

Currently HashiCorp does not provide official Docker images for the
various Enterprise offerings. That will likely change in the near
future. Several of the scenarios in this document require Docker images
with the Enterprise offerings of HashiCorp tools. Most users will likely
find it sufficient to create their own simple Dockerfile which replaces
OSS binaries with the HashiCorp Enterprise versions and then build a
custom Docker image as detailed below.

### Generating Docker images for HashiCorp Consul Enterprise

An example Dockerfile for building Consul Enterprise Docker container
images follows. The examples assume the desired Docker image namespace
for the resulting images will align with the example organization name
of 'exampleorg'.

``` pre
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
```

To build the image:

``` example
$ docker build --rm -t exampleorg/consul-enterprise -f Dockerfile .
```

Note that the resulting image inherits its ENTRYPOINT script, CMD
settings, etc from the upstream Consul OSS Docker image.

The Dockerfile for the Consul OSS image is available
[here](https://github.com/hashicorp/docker-consul/tree/master/0.X/Dockerfile).

### Generating Docker images for HashiCorp Vault Enterprise

The process for building HashiCorp Vault Enterprise Docker container
images is nearly identical as that for generating the Consul Enterprise
images:

``` pre
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
```

To build the image:

``` example
$ docker build --rm -t exampleorg/vault-enterprise -f Dockerfile .
```

Note that the resulting image inherits its ENTRYPOINT script from the
upstream Vault OSS Docker image but overrides the default CMD to disable
Vault [dev
mode](https://www.vaultproject.io/docs/concepts/dev-server.html).

The Dockerfile for the Vault OSS image is available
[here](https://github.com/hashicorp/docker-vault/tree/master/0.X/Dockerfile).

# On-k8s Consul and Vault

In this scenario both Consul and Vault will be deployed on-cluster and
they will be providing services only to other on-k8s workloads.

![Consul and Vault as k8s
workloads](./static/images/consul_vault_on_cluster.png
"consul-vault-on-k8s")

## Consul

Consul will be deployed as a
[StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
with access to
[PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
and the intent is that it be used solely as the Vault [storage
backends](https://www.vaultproject.io/docs/configuration/storage/index.html)
per HashiCorp's documented best practices for Vault Enterprise
deployments. The Consul cluster is composed of 5 servers with all
servers participating in leader elections and quorum consensus. Because
Consul is deployed as a StatefulSet and a [Headless
Service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)
it can be found via [DNS
cluster](https://kubernetes.io/docs/concepts/services-networking/service-dns-pod/)
like so:

``` example
$ kubectl run -ti --image=nrvale0/clusterdebug bash
# host consul.default.svc.cluster.local
consul.default.svc.cluster.local has address 172.17.0.8
consul.default.svc.cluster.local has address 172.17.0.9
consul.default.svc.cluster.local has address 172.17.0.10
consul.default.svc.cluster.local has address 172.17.0.11
consul.default.svc.cluster.local has address 172.17.0.6
# host consul-0.consul.default.svc.cluster.local
consul-0.consul.default.svc.cluster.local has address 172.17.0.6
```

### Deploying the Consul cluster

#### Manifest

Consul can be deployed with kubectl with minor adjustments to the
following YAML. You'll first need to build a Consul Enterprise image as
detailed elsewhere in this doc, that image will need to be available in
a Docker registry, and the YAML will need to be adjusted to reference
those Docker container images. See 'image:' and 'imagePullPolicy' in the
consul.yml.

[consul.yml](https://github.com/hashicorp/hashistack-on-k8s/tree/master/static/examples/consul-vault-on-k8s/consul.yml)

``` yaml
```

#### Deploying and Operating

``` example
$ kubectl apply -f consul.yml
service "consul-ui" created
service "consul" created
configmap "consul-local-config" created
statefulset "consul" created

$ minikube dashboard                          # Will open a web browser to the Kubernetes dashboard.

$ kubectl get statefulset | grep consul       # Display the status of the Consul StatefulSet.
consul    5         5         23m

$ kubectl get pod | grep consul               # See the Consul Pods composing the StatefulSet.
consul-0                 1/1       Running   0          45smmm
consul-1                 1/1       Running   0          41s
consul-2                 1/1       Running   0          32s
consul-3                 1/1       Running   0          29s
consul-4                 1/1       Running   0          24s

$ minikube service --url consul-ui            # Show localhost mapping for the NodePort to the on-cluster Consul service.
http://192.168.99.100:30647

$ xdg-open $(minikube server --url consul-ui) # On Linux, will open a browser to the Consul web UI.
```

Upon successful deployment you will see 5 healthy Consul Server pods in
the Consul UI:

![](./static/images/minikube-consul-consul.png)

#### Additional Important Deployment Notes

The provided YAML:

1.  includes a Service
    [NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)
    for the Consul UI + API port solely as a convenience for interacting
    with Consul from the user's workstation when running minikube.
2.  does ****not**** include specification for node anti-affinity. For
    the greatest availability in a production deployment you should
    specify anti-affinity to ensure that not more than one Consul Pod
    inhabits any single k8s minion/kubelet.
3.  does not provide production-grade
    [livenessProbe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#define-a-liveness-command)
    and
    [readinessProbe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#define-readiness-probes)
    specifications.
4.  does not configure Consul for TLS-protected communication between
    Consul Servers or Clients for the sake of keeping the provided
    example simple.

## Vault

Because it will use the back end Consul for all storage, Vault can be
deployed as a k8s
[Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
instead of a StatefulSet. This also allows for easier upgrades of the
service via the easier-to-use rolling deployment support for Deployments
versus StatefulSets. The Vault cluster will be composed of 3 instances
configured in HA. Vault automatically negotiates a leader election which
results in a single active instances and 2 standbys. Vault clients can
connect to any of the instances without having to negotiate which of the
instances is the active. As with Consul:

1.  the Vault cluster Service is a Headless Service.
2.  a Service NodePort mapping is provided as a convenience to allow
    easy interaction with the Vault service from the user's workstation.
3.  Vault is available via cluster DNS.

<!-- end list -->

``` example
$ kubectl run -ti --image=nrvale0/clusterdebug bash
# host vault.default.svc.cluster.local
vault.default.svc.cluster.local has address 172.17.0.10
vault.default.svc.cluster.local has address 172.17.0.11
vault.default.svc.cluster.local has address 172.17.0.9
```

Its important to note that the resulting Vault instances ****will
not**** be fully operational simply from running kubectl using the
provided YAML specification. The Vault secure storage will need to be
[initialized](https://www.vaultproject.io/intro/getting-started/deploy.html#initializing-the-vault)
and the Operator will need to perform an
[unseal](https://www.vaultproject.io/docs/concepts/seal.html#unsealing)
on each Vault instance. For now, the init and unseal will be performed
manually and later in this doc we'll talk about if and how those steps
should and can be automated.

### Deploying the Vault cluster

Vault can be deployed with kubectl with minor adjustments to the
following YAML. You'll first need to build a Vault Enterprise image as
detailed elsewhere in this doc, that image will need to be available in
a Docker registry, and the YAML will need to be adjusted to reference
those Docker container images. See 'image:' and 'imagePullPolicy' in the
YAML.

#### Manifest

[vault.yml](https://github.com/hashicorp/hashistack-on-k8s/tree/master/static/examples/consul-vault-on-k8s/vault.yml)

``` yaml
```

#### Deploying and Operating

``` example
$ kubectl apply -f vault.yml
service "vault-ui" created
service "vault" created
configmap "vault-local-config" created
configmap "vault-consul-local-config" created
deployment "vault" created

$ kubectl get deployment | grep vault
vault     3         3         3            3           1m

$ kubectl get pod | grep vault
vault-5758659497-dsbws   2/2       Running   0          2m
vault-5758659497-rhc9z   2/2       Running   1          2m
vault-5758659497-xt2gr   2/2       Running   0          2m

$ minikube service --url vault-ui
http://192.168.99.100:32148

$ xdg-open $(minikube service --url vault-ui)
```

##### Init and Unseal

Vault supports the the ability to use a Hardware Security Module(HSM)
for automated
Unsealing\<sup\>[1](https://www.vaultproject.io/docs/enterprise/auto-unseal/index.html),[2](https://www.vaultproject.io/docs/enterprise/hsm/index.html)\</sup\>
of the cryptographic barrier of the back-end storage however, for the
purpose of this documentation, we will rely on the manual method using
Shamir's Secret
Sharing\<sup\>[1](https://www.vaultproject.io/docs/internals/security.html),[2](https://en.wikipedia.org/wiki/Shamir's_Secret_Sharing)\</sup\>.

First let's init the Vault secure storage:

``` example
$ kubectl get pods | grep vault
vault-5758659497-dsbws   2/2       Running   0          52m
vault-5758659497-rhc9z   2/2       Running   1          52m
vault-5758659497-xt2gr   2/2       Running   0          52m

$ kubectl exec -ti vault-5758659497-dsbws -c vault -- /bin/sh -c 'VAULT_ADDR=http://localhost:8200 vault init -key-shares=1 -key-threshold=1'
Unseal Key 1: oVo+GJ+mnPb/bbQvb7mkdLroJjp/v4PgE54bZxERKPw=
Initial Root Token: 02aa27af-cd84-5a15-08a3-0bcd6492e768

Vault initialized with 1 keys and a key threshold of 1. Please
securely distribute the above keys. When the vault is re-sealed,
restarted, or stopped, you must provide at least 1 of these keys
to unseal it again.

Vault does not store the master key. Without at least 1 keys,
your vault will remain permanently sealed.
```

You'll want to record the Unseal Key and Root Token above for use when
unsealing and authenticating to the Vault server
pods.

``` example
$  for v in `kubectl get pods | grep vault | cut -f1 -d' '`; do kubectl exec -ti $v -c vault -- /bin/sh -c 'VAULT_ADDR=http://localhost:8200 vault unseal oVo+GJ+mnPb/bbQvb7mkdLroJjp/v4PgE54bZxERKPw='; done
Sealed: false
Key Shares: 1
Key Threshold: 1
Unseal Progress: 0
Unseal Nonce:
Sealed: false
Key Shares: 1
Key Threshold: 1
Unseal Progress: 0
Unseal Nonce:
Sealed: false
Key Shares: 1
Key Threshold: 1
Unseal Progress: 0
Unseal Nonce:

$ for v in `kubectl get pods | grep vault | cut -f1 -d' '`; do kubectl exec -ti $v -c vault -- /bin/sh -c 'VAULT_ADDR=http://localhost:8200 vault status'; done
Type: shamir
Sealed: false
Key Shares: 1
Key Threshold: 1
Unseal Progress: 0
Unseal Nonce:
Version: 0.9.0.1+ent
Cluster Name: vault-cluster-6781fe0f
Cluster ID: abbfe64b-2bfc-884b-720d-aef198ebaebd

High-Availability Enabled: true
        Mode: active
        Leader Cluster Address: https://172.17.0.9:8201
Type: shamir
Sealed: false
Key Shares: 1
Key Threshold: 1
Unseal Progress: 0
Unseal Nonce:
Version: 0.9.0.1+ent
Cluster Name: vault-cluster-6781fe0f
Cluster ID: abbfe64b-2bfc-884b-720d-aef198ebaebd

High-Availability Enabled: true
        Mode: standby
        Leader Cluster Address: https://172.17.0.9:8201
Type: shamir
Sealed: false
Key Shares: 1
Key Threshold: 1
Unseal Progress: 0
Unseal Nonce:
Version: 0.9.0.1+ent
Cluster Name: vault-cluster-6781fe0f
Cluster ID: abbfe64b-2bfc-884b-720d-aef198ebaebd

High-Availability Enabled: true
        Mode: standby
        Leader Cluster Address: https://172.17.0.9:8201
```

When the Vault storage has been initialized and all of the Vault
instances are unsealed the Consul UI will reflect that fact by coloring
the Vault services green:

``` example
$ xdg-open $(minikube service --url consul-ui)
```

![](./static/images/consul-vault-unsealed.png)

and you should be able to connect and successfully authenticate to the
Vault UI:

``` example
xdg-open $(minikube service --url vault-ui)
```

![](./static/images/vault-auth.png)

#### Additional Important Deployment Notes

The provided YAML:

1.  includes a Service
    [NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)
    for the Vault UI + API port solely as a convenience for interacting
    with Vault from the user's workstation when running minikube.
2.  does ****not**** include specification for node anti-affinity. For
    the greatest availability in a production deployment you should
    specify anti-affinity to ensure that not more than one Vault Pod
    inhabits any single k8s minion/kubelet.
3.  does not provide production-grade
    [livenessProbe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#define-a-liveness-command)
    and
    [readinessProbe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#define-readiness-probes)
    specifications.
4.  does not configure Vault for TLS-protected communication between
    Vault Servers and Clients or the back-end Consul-based storage in
    order to keep the provided example simple.

## Quickstart

Hey, guess what?

``` example
$ git clone https://github.com/hashicorp/hashistack-on-k8s
$ minikube start
$ (cd static/examples/consul-vault-on-k8s && make quickstart)
```

All of that manual stuff in the previous sections….there's a Makefile
which should work for minikube and does the following…

1.  builds the required Docker images for Consul and Vault Enterprise
2.  populates your k8s cluster with the images
3.  deploys Consul and Vault on k8s
4.  performs a Vault init and unseal
5.  runs some validation tests with [Chef
    InSpec](https://www.chef.io/inspec)
6.  provides a set of NodePorts you can use to access Consul and Vault
    UI's and API's

Minimally, you must have the following on your workstation…

  - GNU or BSD Make
  - VirtualBox
  - minikube
  - Docker
  - InSpec
