#!/bin/bash

# install depts
apt-get update -qq
apt-get install unzip curl sudo jq -qq

# install kubectl
cd /usr || exit
mkdir kubectl
cd kubectl || exit
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# copy zip from the secret
mkdir /usr/ravendb-pack
cp /usr/ravendb/pack.zip /usr/ravendb-pack/pack.zip
cd /usr/ravendb-pack || exit

# unzip the pack
unzip -qq pack.zip > /dev/null

node_tag="$(env | grep HOSTNAME | cut -f 2 -d '-')"

cd "${node_tag^^}" || exit

# update secret
kubectl get secret ravendb-certs -o json | jq ".data[\"$node_tag.pfx\"]=\"$(cat ./*certificate* | base64)\"" | kubectl apply -f -
