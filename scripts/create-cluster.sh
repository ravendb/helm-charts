#!bin/bash
apt-get update
apt-get install curl -y
uriB='http://ravendb-1:8080/admin/cluster/node?url=http%3A%2F%2Fravendb-0%3A8080&watcher=false&tag=A' # B->A
uriC='http://ravendb-1:8080/admin/cluster/node?url=http%3A%2F%2Fravendb-2%3A8080&watcher=false&tag=C' # B->C
sleep 10 # wait for nodes to stand-up
curl -L -X PUT $uriB -d ''
curl -L -X PUT $uriC -d ''
