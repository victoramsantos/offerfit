#!/usr/bin/env bash
set -x

LOCAL_HOME="/Users/victor.amorim/Documents/Pessoal/test/offerfit"

# setup k8s cluster
kind create cluster --name offerfit --config ${LOCAL_HOME}/backstage/infra/kind-resources/cluster-config.yaml
kubectl cluster-info --context kind-offerfit

# setup CD with ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f ${LOCAL_HOME}/backstage/cd/argo/manifests/argocd-values.yaml

# setup nginx-ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  -f ${LOCAL_HOME}/backstage/infra/kind-resources/ingress-controller-values.yaml

# force the app build
docker build ${LOCAL_HOME}/app/service-a/. -t victoramsantos/offerfit-service-a:test
docker build ${LOCAL_HOME}/app/service-b/. -t victoramsantos/offerfit-service-b:test

# wait for ArgoCD and Ingress components start
sleep 10

# Deploy the ArgoCD Application for both apps
kubectl apply -f ${LOCAL_HOME}/app/service-a/deploy-config/application.yaml
kubectl apply -f ${LOCAL_HOME}/app/service-b/deploy-config/application.yaml

# Add ingresses
## argocd
kubectl apply -f ${LOCAL_HOME}/backstage/cd/argo/manifests/argocd-ingress.yaml

# Print the ArgoCD admin's password
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ARGOCD_PASS = ${ARGOCD_PASS}"

echo "Bootstrap has been finished:"
echo "Please check status on http://argocd.offerfit.local"