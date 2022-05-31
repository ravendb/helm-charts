#!/bin/bash
# This script is executing rolling update and takes the new ravenImageTag value as an first argument
# As a second argument pass path to your ravendb-cluster
echo "Installing yq"
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod a+x /usr/local/bin/yq


if [ $# != 2 ]
then
echo "Please pass two args, ravenImageTag and path to ravendb-cluster"
exit 0
fi

getPodsResult=$(kubectl get pods -n ravendb)
if [ $? -ne 0 ]; then
echo "Couldn't get " 
exit 1
fi

for pod in $(echo "$getPodsResult" | awk '{ print $1 }' | grep ravendb-.-)
do

statefulsetname="$(echo "$pod"|cut -f 1-2 -d '-')"
url="$(kubectl describe pod "$pod" -n ravendb | grep PublicServerUrl | head -1 | awk '{print $2}')"

echo "Setting image $1 on the $pod"
kubectl set image statefulset/"$statefulsetname" ravendb-container=ravendb/ravendb:"$1" -n ravendb

status=""
echo "Waiting for $pod..."
while [ "$status" != "Running" ]
do
echo "Current $pod status: $status"
status="$(kubectl get pod -n ravendb | grep "$pod" | awk '{print $3}')"
sleep 3
done
echo "Waiting for RavenDB alive status"
while ! curl "$url/setup/alive"
do
    echo -n "."
    sleep 3
done

echo "Successfully updated $statefulsetname"

done

echo "Updating $2/values.yaml 'ravenImageTag' field"
yq -i '.ravenImageTag="'"$1"'"' $2/values.yaml
exit 0
