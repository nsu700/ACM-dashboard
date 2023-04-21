# ACM-dashboard

## How to use this repo
1. Install ACM operator
2. Run the `enableObservalibility.sh` script to enable monitoring component of ACM
3. Apply the `observability-metrics-custom-allowlist.yaml` to create the allow list of metrics
4. (Option) If need monitoring on certificate expiry status, install https://github.com/redhat-cop/cert-utils-operator
5. (Option) If Step4 done, run `oc label namespace cert-utils-operator openshift.io/cluster-monitoring="true"` or the metrics will not be collected by prometheus
6. Import the json file of dashboard

## How to import the json file into ACM grafana
`oc kustomize ./ | oc apply -f- -n open-cluster-management-observability`

## How to enable alerting 
https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/observability/index#configuring-alertmanager

## Current Dashboards
1. Cluster Overview
2. Project Details

