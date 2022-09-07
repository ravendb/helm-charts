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

# todo: register a client ceritifacte

urls=()
tags=()
domain_name="$(cat /ravendb/scripts/domain)"

for i in ../* ; do
  if [ -d "$i" ]; then
    tag="$(basename "$i" | tr '[:upper:]' '[:lower:]')"
    tags+=("$tag")
    if [ "$tag" != "a" ]; then
        urls+=("https://a.$domain_name/admin/cluster/node?url=https%3A%2F%2F$tag.$domain_name&tag=$(echo "$tag" | tr '[:lower:]' '[:upper:]')")
    fi
  fi
done

# convert .pfx to .pem
echo "Converting pfx to pem..."
openssl pkcs12 -in "$(find ./*certificate*)" -password pass: -out cert.pem -nodes -legacy

# send requests that will create cluster using converted certificate 
for tag in "${tags[@]}"
do
while ! curl "https://$tag.$domain_name/setup/alive"
do
    echo -n "$tag... "
    sleep 3
done
done

echo "Sending requests..."
echo "${urls[@]}"
for url in "${urls[@]}"
do
    echo "Sending request connecting node A with node under the $url"
    curl -L -X PUT "$url" --cert cert.pem
done
