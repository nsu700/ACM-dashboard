#!/bin/bash
set -x
BUCKET=rosatestnsubucketacm
REGION=southeastasia
RSNAME=nsutestarorg
SANAME=nsutestsa
CONTAINER=acm

# az login
az login

# az create resource group
az group create --name $RSNAME --location $REGION

# az create storage account
az storage account create --name $SANAME --resource-group $RSNAME --location $REGION --sku Standard_RAGRS --kind StorageV2

# ac create container
az storage container create -n $SANAME

# get azure storage account key
az storage account keys list -g $RSNAME -n $SANAME | jq '.[0].value'

oc create namespace open-cluster-management-observability
DOCKER_CONFIG_JSON=`oc extract secret/multiclusterhub-operator-pull-secret -n open-cluster-management --to=-`
[[ "x$DOCKER_CONFIG_JSON" == "x" ]] && DOCKER_CONFIG_JSON=`oc extract secret/pull-secret -n openshift-config --to=-`

oc create secret generic multiclusterhub-operator-pull-secret \
    -n open-cluster-management-observability \
    --from-literal=.dockerconfigjson="$DOCKER_CONFIG_JSON" \
    --type=kubernetes.io/dockerconfigjson

echo " 
apiVersion: v1
kind: Secret
metadata:
  name: thanos-object-storage
  namespace: open-cluster-management-observability
type: Opaque
stringData:
  thanos.yaml: |
    type: AZURE
    config:
      storage_account: $SANAME
      storage_account_key: $SAKEY
      container: $CONTAINER
      endpoint: blob.core.windows.net
      max_retries: 0" | oc apply -f -

echo "
apiVersion: observability.open-cluster-management.io/v1beta2
kind: MultiClusterObservability
metadata:
  name: observability
  namespace: open-cluster-management-observability
spec:
  observabilityAddonSpec: {}
  storageConfig:
    metricObjectStorage:
      name: thanos-object-storage
      key: thanos.yaml" | oc apply -f -
