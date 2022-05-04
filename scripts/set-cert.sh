#!/bin/bash

# install depts
apt-get update -qq
apt-get install unzip -qq
apt-get install curl -qq
apt-get install sudo -qq
apt-get install jq -qq

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
cd A || exit

# update secret
kubectl get secret ravendb-certs -o json | jq ".data[\"cert.pfx\"]=\"$(cat ./*certificate* | base64)\"" | kubectl apply -f -
