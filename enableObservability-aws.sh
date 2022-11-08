#!/bin/bash
set -x
BUCKET=rosatestnsubucketacm
REGION=ap-south-1

[ -f ~/.aws/credentials ] && AWS_KEY=$(awk -v FS="=" '/aws_access_key_id/{print $2}' ~/.aws/credentials) && AWS_SECRET=$(awk -v FS="=" '/aws_secret_access_key/{print $2}' ~/.aws/credentials)

# Create an AWS S3 bucket
aws s3api create-bucket --bucket $BUCKET --region $REGION --create-bucket-configuration LocationConstraint=$REGION

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
    type: s3
    config:
      bucket: $BUCKET
      endpoint: s3.amazonaws.com
      insecure: true
      access_key: $AWS_KEY
      secret_key: $AWS_SECRET" | oc apply -f -

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
