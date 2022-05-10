#!/bin/bash

# install depts
apt-get update -qq
apt-get install unzip curl sudo jq -qq

# install kubectl
echo "Installing kubectl..."
cd /usr || exit
mkdir kubectl
cd kubectl || exit
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# copy zip from the secret
echo "Copying /usr/ravendb/pack/.zip to /ravendb"
cp /usr/ravendb/pack.zip /ravendb/pack.zip
cd /ravendb || exit

# unzip the pack
echo "Extracting files from the pack..."
mkdir /ravendb/ravendb-pack
unzip -qq pack.zip -d ./ravendb-pack/ > /dev/null
cd ravendb-pack || exit

echo "Reading node tag from the HOSTNAME environmental..."
node_tag="$(env | grep HOSTNAME | cut -f 2 -d '-')"
cd "${node_tag^^}" || exit

# update secret
echo "Updating secret using kubectl get and kubectl apply..."
kubectl get secret ravendb-certs -o json | jq ".data[\"$node_tag.pfx\"]=\"$(cat ./*certificate* | base64)\"" | kubectl apply -f -
