#!/bin/bash
apt-get update -qq > /dev/null
apt-get install unzip -qq > /dev/null

# copy zip from the secret
mkdir /usr/ravendb-pack
cp /usr/ravendb/pack.zip /usr/ravendb-pack/pack.zip
cd /usr/ravendb-pack || exit

# unzip the pack
unzip -qq pack.zip > /dev/null
cd A || exit

# print .pfx
cat -u ./*certificate*
exit