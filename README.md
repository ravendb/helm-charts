Work in progress, use only for testing.

# Official Helm chart for RavenDB NoSQL Database  ☸️

## Installation

`helm install [name] [chart path]`


Before installation you need to specify your RavenDB license file path inside `values.yaml`, or copy the license json to the  `misc/license.json` file.


![](.github/helm_install.gif)

---

## Local testing
Make sure you have properly configured nginx ingress controller.
Read/follow the steps from the nginx dedicated note inside `values.yaml` file.

You might need to make sure that your DNS is correctly configured, pods need records that translate `<nodeTag>{-tcp}.[domain]` names to ingress controller IP address.

e.g. Additional record inside /etc/hosts file, `192.168.1.15` is my local IP address, running nginx on local machine k8s cluster

```
192.168.1.15 a.poisson.development.run b.poisson.development.run c.poisson.development.run 
192.168.1.15 a-tcp.poisson.development.run b-tcp.poisson.development.run c-tcp.poisson.development.run 
```




*These records can't point to localhost loopback/0.0.0.0, basically it'll tell the pods to reach nginx on themselves, not on our machine.*

TBA 🔌

