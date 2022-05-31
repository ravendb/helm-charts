# Secured RavenDB Cluster Helm Chart ☸️

## Overview
This Helm chart provides all necessary components for the secured RavenDB cluster. It's very easy to deploy & manage your own RavenDB cluster by using it.


## Prerequisites 

- RavenDB License (obtained via https://ravendb.net - also works with the free developer license)
- RavenDB Setup Package (created using RavenDB Setup Wizard or with the *rvn* utility)


## Installation

`helm install [name] [chart path]`


Before installation you should customize `values.yaml`.
- Enter your *domain name* and path to *RavenDB setup package*.
- Enter how much `storageSize` would you like to have on each node.
- Optionally, provide a desired RavenDB image tag (`latest` by default).
- In some cases you might want to edit [image pull policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy).
- If you need some environmental values inside the RavenDB container, you can define them in the `environment` map.

### Example values.yaml

```yaml
domain: "ravendb.poisson.net"
ravenImageTag: latest
packageFilePath: misc/pack.zip
storageSize: 5Gi
ingressClassName: nginx
imagePullPolicy: IfNotPresent

nodes:
  - nodeTag: "A"
    publicTcpPort: 38887
  - nodeTag: "B"
    publicTcpPort: 38888
  - nodeTag: "C"
    publicTcpPort: 38889

environment:
  SOME_ENV_VALUE: 'foo'
  SOME_OTHER_ENV_VALUE: 'bar'
```

 

![](.github/helm_install.gif)


## How do I make this work?

## Configure your DNS 

Make sure that your DNS contains records that translate RavenDB nodes addresses to the ingress controller IP address. Pods need these to talk to each self. You need to translate 
- `<nodeTag>.[domain]`
- `<nodeTag>-tcp.[domain]`

names to ingress controller IP address.

---
*e.g. Additional record inside /etc/hosts file, `192.168.1.15` is my local IP address, running nginx on local machine k8s cluster*

```
192.168.1.15 a.raven.domain.com b.raven.domain.com c.raven.domain.com 
192.168.1.15 a-tcp.raven.domain.com b-tcp.raven.domain.com c-tcp.raven.domain.com 
```

*Dns records can't point to localhost/loopback/0.0.0.0, basically it'll tell the pods to reach nginx on themselves, not on our machine - use your local IP address.*


## Set up your ingress controller

It must be able to **expose tcp services** and **passthrough SSL** like Nginx/HAProxy.


## NGINX

You need to deploy nginx with additional `--tcp-services-configmap=ingress-nginx/tcp-services` arg.
For secured cluster configuration it is also needed to use `--enable-ssl-passthrough` option.

### Deploying Nginx on Kubernetes

If you've deployed k8s nginx before, its dependencies are frequently stored in the 'ingress-nginx' namespace.
You can deploy nginx to k8s using the `nginx-ingress-ravendb.yaml` file located in the misc folder, which is preconfigured for default nodes/tags/ports and secured connection.
It is not necessary, but running `kubectl delete all --all -n ingress-nginx` should delete all nginx k8s depts before another deployment.
Run `kubectl apply -f [path to 'nginx-ingress-ravendb' file]` to either update or install well configured nginx ingress controller locally.

If you want to configure it manually, make sure that...
- ... services that route to nginx pod expose public tcp ports of RavenDB nodes (38887, 38888 and 38889 by default)
- ... port 38888 (or your own ServerUrl_Tcp port) is exposed on the nginx controller pod
- ... --enable-ssl-passthrough is set (when working with secured cluster)

## HAProxy, Traefik and others

For first and most important, **check if your ingress controller supports exposing TCP services**. If it does, start with changing the `ingressClassName` in the `values.yaml`, enter your deployed ingress class name.

e.g. `ingressClassName: haproxy`

Configuring HAProxy
- https://haproxy-ingress.github.io/docs/configuration/command-line/#tcp-services-configmap

Traefik is a bit complex
- https://github.com/traefik/traefik/issues/4981
- https://github.com/traefik/traefik/pull/4587

Also, remember to enable SSL passtrough on your ingress controller
https://doc.traefik.io/traefik/routing/routers/#passthrough
https://serversforhackers.com/c/using-ssl-certificates-with-haproxy


## Rolling updates

You can perform rolling update using the `rolling-update.sh` script located in the `/scripts` directory. Provide desired RavenDB image tag from the DockerHub https://hub.docker.com/r/ravendb/ravendb/tags as the first arg and path to the Helm chart as the second.

`./rolling-update.sh latest ~/ravendb-chart`

It'll execute rolling update strategy and update your pods image tags.