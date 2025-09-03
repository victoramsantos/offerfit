#!/usr/bin/env bash
set -x

LOCAL_HOME="/Users/victor.amorim/Documents/Pessoal/test/offerfit"

kind create cluster -n offerfit
kubectl cluster-info --context kind-offerfit

helm install argocd argo/argo-cd -n argocd -f ${LOCAL_HOME}/backstage/cd/argo/manifests/argocd-values.yaml --create-namespace

docker build ${LOCAL_HOME}/app/service_a/. -t victoramsantos/offerfit-service-a:test
docker build ${LOCAL_HOME}/app/service_b/. -t victoramsantos/offerfit-service-b:test

sleep 5

kubectl apply -f ${LOCAL_HOME}/app/service_a/deploy-config/application.yaml
kubectl apply -f ${LOCAL_HOME}/app/service_b/deploy-config/application.yaml

ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ARGOCD_PASS = ${ARGOCD_PASS}"

kubectl port-forward service/argocd-server -n argocd 8080:443

