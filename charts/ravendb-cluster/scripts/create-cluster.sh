#!/bin/bash

set -e

echo "Installing prerequisites..."
# prerequisites
apt-get update
apt-get install curl unzip jq -y

# copy the package from readonly volume
echo "Copying /ravendb/ravendb-setup-package-readonly/pack.zip to the /ravendb folder..."
cp -v /ravendb/ravendb-setup-package/*.zip /ravendb/pack.zip

# unzip the pack
echo "Extracting files from the pack..."
mkdir /ravendb/ravendb-setup-package-copy
cd /ravendb
unzip -qq pack.zip -d ./ravendb-setup-package-copy/ > /dev/null
cd ravendb-setup-package-copy/A

domain_name="$(cat /ravendb/scripts/domain)"

# convert .pfx to .pem
echo "Converting pfx to pem..."
openssl pkcs12 -in "$(find ./*certificate*)" -password pass: -out cert.pem -nodes -legacy

# send requests that will create cluster using converted certificate 
uriB="https://a.$domain_name/admin/cluster/node?url=https%3A%2F%2Fb.$domain_name&watcher=false&tag=B"
uriC="https://a.$domain_name/admin/cluster/node?url=https%3A%2F%2Fc.$domain_name&watcher=false&tag=C"
echo "Waiting for nodes to stand up..." 

tags=("a" "b" "c")


for tag in "${tags[@]}"
do
while ! curl "https://$tag.$domain_name/setup/alive"
do
    echo -n "."
    sleep 3
done
done

echo
echo "Sending requests..."
curl -L -X PUT "$uriB" --cert cert.pem
curl -L -X PUT "$uriC" --cert cert.pem
