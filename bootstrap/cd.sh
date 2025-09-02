
helm install argocd argo/argo-cd -n argocd -f ./backstage/cd/argo/manifests/argocd-values.yaml --create-namespace

kubectl port-forward service/argocd-server -n argocd 8080:443

helm uninstall argocd -n argocd
