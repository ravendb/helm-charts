#!/bin/bash
apt-get update
apt-get install curl -y
apt-get install unzip -y
mkdir /usr/ravendb-pack 
cp /usr/ravendb/pack.zip /usr/ravendb-pack/pack.zip

cd /usr/ravendb-pack || exit
unzip -qq pack.zip
cd A || exit

domain_name=$( tail -2 settings.json | head -1 | cut -f 3 -d : | cut -c 5-)
domain_name_values="$(cat /usr/scripts/domain)"
if [ "$domain_name" != "$domain_name_values" ]; then
    echo "Domain name from values.yaml doesn't match domain name from the .zip package"
    exit
fi

openssl pkcs12 -in "$(find ./*certificate*)" -password pass: -out cert.pem -nodes -legacy

# todo: get nodes tags from .Values
# todo: validate that domain name from .Values is identical to the package domain name 

uriB='https://a.'$domain_name'/admin/cluster/node?url=https%3A%2F%2Fb.'$domain_name'&watcher=false&tag=B'
uriC='https://a.'$domain_name'/admin/cluster/node?url=https%3A%2F%2Fc.'$domain_name'&watcher=false&tag=C'

sleep 75 # wait for nodes to stand-up
curl -L -X PUT "$uriB" --cert cert.pem
curl -L -X PUT "$uriC" --cert cert.pem
