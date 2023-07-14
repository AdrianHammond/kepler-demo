#!/bin/sh

# Applying dashboard/kustomization.yaml does the following:
## Enables dashboard for Kepler on OpenShift
## Setup service monitor policy
## Installs Grafana community operator
## Creates Grafana instance

oc apply --kustomize .

# moved to above while loop
oc apply -f 02-grafana-instance.yaml

while ! oc get grafana --all-namespaces
do
    echo waiting for grafana custom resource definition to register
    sleep 5
done

# changed apply to create to avoid labelling error message
oc create -f 02-grafana-sa.yaml

oc apply -f 03-grafana-sa-token-secret.yaml

# moved hile loop directly after secret creation
while ! oc get serviceaccount $SERVICE_ACCOUNT -n kepler
do
    sleep 2
done

SERVICE_ACCOUNT=grafana-serviceaccount
SECRET=grafana-sa-token


# Define Prometheus datasource
oc adm policy add-cluster-role-to-user cluster-monitoring-view -z $SERVICE_ACCOUNT -n kepler

# Get bearer token for `grafana-serviceaccount`
export BEARER_TOKEN=$(oc get secret ${SECRET} -o json -n kepler | jq -Mr '.data.token' | base64 -d) || or true

while [ -z "$BEARER_TOKEN" ]
do
    echo waiting for service account token
    export BEARER_TOKEN=$(oc get secret ${SECRET} -o json -n kepler | jq -Mr '.data.token' | base64 -d) || or true
    sleep 1
done
echo service account token is populated, will now create grafana datasource

# Deploy from updated manifest, moved before while loop
envsubst < 03-grafana-datasource-UPDATETHIS.yaml | oc apply -f -

while ! oc get grafanadatasource --all-namespaces;
do
    sleep 1
    echo waiting for grafanadatasource custom resource definition to register
done

oc apply -f 04-grafana-dashboard.yaml

# Define Grafana dashboard
while ! oc get grafanadashboard --all-namespaces;
do
    sleep 1
    echo waiting for grafandashboard custom resource definition to register
done


