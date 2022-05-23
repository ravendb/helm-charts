# Official Helm chart for RavenDB NoSQL Database  ☸️

## Overview
This Helm chart provides all necessary components for the secured RavenDB cluster. It's very easy to deploy & manage your own RavenDB cluster by using it.

---

## Installation

`helm install [name] [chart path]`


Before installation you need to specify your RavenDB license file path inside `values.yaml`, or copy the license json to the  `misc/license.json` file.
Also, provide your domain name, Let's Encrypt email, and path to RavenDB certificates & license package (e.g. from `rvn create-package` tool).

Optionally, you can provide a custom version of RavenDB (latest by default) or a node storage size.
 

![](.github/helm_install.gif)

---

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

---

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

----

## Rolling updates
You can perform rolling update using the `rolling-update.sh` script located in the `/scripts` directory. Provide desired RavenDB image tag from the DockerHub https://hub.docker.com/r/ravendb/ravendb/tags as the first arg and path to the Helm chart as the second.

`./rolling-update.sh latest ~/ravendb-chart`

It'll execute rolling update strategy and update your pods image tags.
