Work in progress.

# Official Helm chart for RavenDB NoSQL Database  ☸️

## Installation

`helm install [name] [chart path]`


Before installation you need to specify your RavenDB license file path inside `values.yaml`, or copy the license json to the  `misc/license.json` file.
Also, provide your domain name and path to RavenDB certificates & license package (e.g. from `rvn create-package` tool).
Optionally, provide a version of RavenDB (latest by default).


![](.github/helm_install.gif)

---

## Usage
Make sure you have properly configured nginx ingress controller.
Read/follow the steps from the nginx dedicated note below.

You might need to make sure that your DNS is correctly configured, pods need records that translate `<nodeTag>{-tcp}.[domain]` names to ingress controller IP address.

e.g. Additional record inside /etc/hosts file, `192.168.1.15` is my local IP address, running nginx on local machine k8s cluster

```
192.168.1.15 a.poisson.development.run b.poisson.development.run c.poisson.development.run 
192.168.1.15 a-tcp.poisson.development.run b-tcp.poisson.development.run c-tcp.poisson.development.run 
```

*Dns records can't point to localhost/loopback/0.0.0.0, basically it'll tell the pods to reach nginx on themselves, not on our machine - use your local IP address.*

## NGINX
You need to deploy nginx with additional `--tcp-services-configmap=ingress-nginx/tcp-services` arg due to issues with exposing tcp service on ingress
For secured cluster configuration it is also needed to use `--enable-ssl-passthrough` option
If you've deployed k8s nginx before, its dependencies are frequently stored in the 'ingress-nginx' namespace 
You can deploy nginx to k8s using the `nginx-ingress-ravendb.yaml` file located in the misc folder, which is preconfigured for default nodes/tags/ports and secured connection
It is not necessary, but running `kubectl delete all --all -n ingress-nginx` should delete all nginx k8s depts before another deployment
Run `kubectl apply -f [path to 'nginx-ingress-ravendb' file]` to either update or install well configured nginx ingress controller locally

Manual configuration of k8s nginx:
- Make sure that services that route to nginx pod expose also public tcp ports of RavenDB nodes like 38887, 38888 and 38889 
- Make sure that port 38888 (or your own ServerUrl_Tcp port) is exposed from nginx controller pod
- Make sure that --enable-ssl-passthrough is enabled when working with secured cluster

