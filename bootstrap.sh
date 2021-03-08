#!/bin/bash

export KUBE_APP_NAMESPACE=koncepts-demo

terraform apply -auto-approve

aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)


kubectl create namespace $KUBE_APP_NAMESPACE
kubectl config set-context --current --namespace $KUBE_APP_NAMESPACE

kubectl apply -f https://raw.githubusercontent.com/smrowley/koncepts/master/kube/config.yaml
kubectl apply -f https://raw.githubusercontent.com/smrowley/koncepts/master/kube/deploy.yaml
kubectl apply -f https://raw.githubusercontent.com/smrowley/koncepts/master/kube/load-balancer-svc.yaml


kubectl get svc koncepts-demo-lb --template='{{"Hostname:\n"}}{{range.status.loadBalancer.ingress}}{{.hostname}}{{"\n"}}{{end}}'