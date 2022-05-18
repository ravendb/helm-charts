#!/bin/bash

set -e

# install depts
apt-get update -qq
apt-get install unzip curl sudo jq -qq

# install kubectl
echo "Installing kubectl..."
cd /usr
mkdir kubectl
cd kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# copy zip from the secret
echo "Copying RavenDB setup package to /ravendb"
cp /usr/ravendb/pack.zip /ravendb/pack.zip
cd /ravendb

# unzip the pack
echo "Extracting files from the pack..."
mkdir /ravendb/ravendb-setup-package
unzip -qq pack.zip -d ./ravendb-setup-package/ > /dev/null
cd ravendb-setup-package

echo "Reading node tag from the HOSTNAME environmental..."
node_tag="$(env | grep HOSTNAME | cut -f 2 -d '-')"
cd "${node_tag^^}"

# update secret
echo "Updating secret using kubectl get and kubectl apply..."
kubectl get secret ravendb-certs -o json -n ravendb | jq ".data[\"$node_tag.pfx\"]=\"$(cat ./*certificate* | base64)\"" | kubectl apply -f -
