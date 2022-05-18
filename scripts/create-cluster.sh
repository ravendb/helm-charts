#!/bin/bash
echo "Installing prerequisites..."
# prerequisites
apt-get update
apt-get install curl unzip -y

# copy the package from readonly volume
echo "Copying /ravendb/ravendb-setup-package-readonly/pack.zip to the /ravendb folder..."
cp -v /ravendb/ravendb-setup-package/pack.zip /ravendb/pack.zip

# unzip the pack
echo "Extracting files from the pack..."
mkdir /ravendb/ravendb-setup-package-copy
cd /ravendb || exit 1
unzip -qq pack.zip -d ./ravendb-setup-package-copy/ > /dev/null
cd ravendb-setup-package-copy/A || exit 1

# fetch domain name and validate it
echo "Validating domain name..."
domain_name=$( tail -2 settings.json | head -1 | cut -f 3 -d : | cut -c 5-)

domain_name_values="$(cat /ravendb/scripts/domain)"
if [ "$domain_name" != "$domain_name_values" ]; then
    echo "Domain name from values.yaml doesn't match domain name from the .zip package"
    exit
fi

# convert .pfx to .pem
echo "Converting pfx to pem..."
openssl pkcs12 -in "$(find ./*certificate*)" -password pass: -out cert.pem -nodes -legacy

# todo: get nodes tags from .Values

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
