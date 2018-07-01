# terraform-kubernetes

## 1. Creating Cluster

```bash
# export variables
$(cat generated.kops-env.sh)
echo $NAME $KOPS_STATE_STORE

# generate terraform resource, will generate `kubernetes.tf` and `data/`
./generated.kops-create.sh
ls data/ kubernetes.tf

terraform plan
terraform apply

# update without pod draining
kops rolling-update cluster $NAME --cloudonly        # preview
kops rolling-update cluster $NAME --cloudonly --yes  # execute

# validate
kops export kubecfg --name=$NAME
./generated.correct-kubectl-context.sh
kops validate cluster
kubectl get nodes
```

### Trouble Shooting

#### Problem: No such host when `kubectl`

```bash
Unable to connect to the server: dial tcp: lookup api.kops.bank.kakao.enterprise.zepl.k8s.local on 8.8.8.8:53: no such host

kops export kubecfg --name=$NAME
```

#### Problem: X.509 Cert

If you hit SSL issues like this, Please refer [this ticket](https://github.com/kubernetes/kops/issues/2990#issuecomment-396096526).

```bash
$ kops validate cluster
Validating cluster kops.PROJECT.ENTERPRISE.enterprise.zepl.k8s.local

unexpected error during validation: error listing nodes: Get https://api-kops-XXX.ap-northeast-1.elb.amazonaws.com/api/v1/nodes: x509: certificate is valid for api.internal.kops.porject.company.enterprise.zepl.k8s.local, api.kops.project.company.enterprise.zepl.k8s.local, kubernetes, kubernetes.default, kubernetes.default.svc, kubernetes.default.svc.cluster.local, not api-kops-project-company--oakbcb-247697005.ap-northeast-1.elb.amazonaws.com
```

Then, try to execute `./generated.correct-kubectl-context.sh`
**If it doesn't work**, then follow this instruction.

```
kops export kubecfg --name=$NAME
kops update cluster $NAME --target=terraform --out=.

terraform init
terraform plan
terraform apply

kops rolling-update cluster  --cloudonly --force --yes
```

## 2. Deploying add-ons + Creating kubectl context for a deployer

- [x] 2.1 Creating kubectl context
- [x] 2.2 ACM + Nginx Ingress + installed by Helm Tiller
- [x] 2.3 Creating Programming Access Key for ECS accessible IAM
- [x] 2.4 Creating docker-registry
- [x] 2.5 (optional) Dashboard + Heapster
- [x] 2.6 (optional) EFK + ES Curator

### 2.1 Creating kubectl context

Move to the `kubectx-create/` dir and follow instruction of the README.md file there

```bash
cd kubectx-create/
```

### 2.2 ACM + Nginx Ingress

To instal [helm](https://helm.sh/), Please follow these instructions below.

```bash
brew install kubernetes-helm
brew upgrade kubernetes-helm
```

Then, need to create external endpoint. **Make sure that your ACM is not pending state**

```bash
# install tiller server on kubernetes cluster
kubectl apply -f addon-ingress/tiller-clusterolebinding.yaml
helm init --service-account tiller --upgrade

helm repo update
./addon-ingress/generated.install-chart.sh

# debug, delete commands
helm ls
helm delete global-entry; helm del --purge global-entry;
```

To get the exposed ELB DNS name,

```bash
kubectl get service --namespace default global-entry-nginx-ingress-controller -o json | jq -r '.status.loadBalancer.ingress[0].hostname'
```

### 2.3 Creating Programming Access Key for ECS accessible IAM
Please using AWS management console - IAM user

### 2.4 Creating docker-registry

```bash
# make sure that you exported `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
export IAM={username} AWS_ACCESS_KEY_ID={access-key} AWS_SECRET_ACCESS_KEY={secret-key} 
./generated.docker-registry.sh
```

### 2.5 (optional) Kubernetes Dashboard

```bash
kubectl apply -f addon-dashboard/heapster-influx-v1.3.3.yaml -f addon-dashboard/heapster-v1.4.2.yaml
kubectl apply -f addon-dashboard/kubernetes-dashboard-v1.8.3.yaml
kubectl proxy

# verification
stern --since 10m -n kube-system -l k8s-app=kubernetes-dashboard
stern --since 10m -n kube-system -l k8s-app=heapster
```

- [Kubernetes Dashboard URL](http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/node?namespace=kube-system)

### 2.6 (optional) EKF + ES Curator

```bash
kubectl apply -f addon-EFK/es-statefulset.yaml
kubectl apply -f addon-EFK/kibana-deployment.yaml
kubectl apply -f addon-EFK/es-curator-v1beta1.yaml
kubectl apply -f addon-EFK/fluentd-es-ds.yaml

# verifcation
stern --since 10m -n kube-system -l k8s-app=elasticsearch-logging
stern --since 10m -n kube-system -l k8s-app=kibana-logging
stern --since 10m -n kube-system -l k8s-app=fluentd-es
```

- [Kibana URL](http://localhost:8001/api/v1/namespaces/kube-system/services/kibana-logging/proxy/app/kibana#)

