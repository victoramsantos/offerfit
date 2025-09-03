
kind create cluster -n offerfit

kubectl cluster-info --context kind-offerfit

helm install argocd argo/argo-cd -n argocd -f ./backstage/cd/argo/manifests/argocd-values.yaml --create-namespace

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

kubectl port-forward service/argocd-server -n argocd 8080:443


kubectl apply -f app/service_a/deploy-config/application.yaml

# uninstall
helm uninstall argocd -n argocd
