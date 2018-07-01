#!/usr/bin/env bash

TAG="[$$(basename -- "$$0")]"

dns=$(aws elb describe-load-balancers --region ${region} | jq ".LoadBalancerDescriptions" | jq -r ".[] | select(.DNSName | contains(\"api-kops-${project}-${company}\")) | .DNSName")

echo "$${TAG} Kubernetes API ELB DNS: $${dns}\n"
kubectl config set-cluster ${kops_cluster_name} --server="https://$${dns}" --insecure-skip-tls-verify=true

echo -e ""
echo -e "$${TAG} kubectl get nodes"
kubectl get nodes
