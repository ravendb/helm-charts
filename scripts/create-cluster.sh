#!bin/bash
apt-get update
apt-get install curl -y
uriB='http://a.poisson.development.run/admin/cluster/node?url=http%3A%2F%2Fb.poisson.development.run&watcher=false&tag=B' 
uriC='http://a.poisson.development.run/admin/cluster/node?url=http%3A%2F%2Fc.poisson.development.run&watcher=false&tag=C' 
sleep 10 # wait for nodes to stand-up
curl -L -X PUT $uriB -d ''
curl -L -X PUT $uriC -d ''
