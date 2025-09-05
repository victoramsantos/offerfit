# CI/CD - Braze/Offerfit Contest

This is a Continuous Integration and Continuous Delivery (CI/CD) project that deploys two Python applications, 
namely [service-a](app/service-a) and [service-b](app/service-a), into a local kubernetes cluster and use the repository 
(https://github.com/victoramsantos/offerfit) as a source of truth.

## Methodology
### Application

Both applications are simple services which two main APIs:

**/health** - *Which returns a 200 and this response:*
```json
{
  "Status": "Success"
}
```

**/version** - *Which returns a 200 and this response, where `$APP_VERSION` refers to the current application version:*
```json
{
  "version": $APP_VERSION
}
```

For the `service-a` we also have:
**/ping** - *Which returns a 200 and this response:*
```json
{
  "message": "Greetings from Service A!"
}
```

For the `service-b` we have:
**/ping_service_a** - *Which calls the `service-a`'s `/ping` API and returns its response, appending some message to it, like:*
```json
{
  "message": "{$SERVICE_A:/ping} (via Service B)"
}
```

For both applications, I added a few unittests, which are under the `src` folder of each application: 
- [service-a unittests](app/service-a/src/test_main.py)
- [service-b unittests](app/service-b/src/test_main.py)


### Building the applications

I used Docker to containerize the application. Both of them have a [Dockerfile](app/service-a/Dockerfile) that builds its image.
The images are stored on my personal Docker Hub registry:
- service-a: https://hub.docker.com/repository/docker/victoramsantos/offerfit-service-a
- service-b: https://hub.docker.com/repository/docker/victoramsantos/offerfit-service-b

### Continuous Integration

I'm using [Github Actions](https://docs.github.com/en/actions) to apply **GitOps**.
> GitOps is a branch of DevOps that focuses on using Git code repositories to manage infrastructure and application code deployments.

With this in mind, we have that the project's git repository is the source of truth, so every change on the repository will trigger some action in the CI or CD tools.

I defined two environments for this project, namely `developer` and `production`.

For the `developer` environment, we have the gitflow:
- When everything is merged to the `main` branch
- The [Python CI](.github/workflows/python-ci.yaml) will run all the unittests.
- Only if all tests passed, then the [Build and Publish](.github/workflows/build-and-publish.yaml) workflow will be triggered.
  - This workflow will build a new docker image and will use the seven first characters of the commit to push a new image to the Docker Hub Registry (ex: [victoramsantos/offerfit-service-a:079d74d](https://hub.docker.com/repository/docker/victoramsantos/offerfit-service-a/tags/079d74d/sha256:d74b5a215a4c7fc11c06ece0b4f438da1ed2ad2ec6602c6742c8af4098045734))
- Only if both application's images were pushed successfully to the registry, then the [Image Update and Push](.github/workflows/image-update-and-push.yaml) is called.
  - This workflow will create a new commit to the main branch to update the [values.yaml](app/service-a/deploy-config/developer/values.yaml) `tag` value with this commit.
  - This tag will be used next by ArgoCD to update the application on the cluster.

For the `production` environment, we have the flow:
- In this environment, it will be only deployed releases.
- For every release published on the repository, the [Tag Release](.github/workflows/tag-release.yaml) will be called.
  - This workflow will build a new docker image using the tag name and will push it to the Docker Hub Registry (ex: [victoramsantos/offerfit-service-a:v0.0.4](https://hub.docker.com/repository/docker/victoramsantos/offerfit-service-a/tags/v0.0.4/sha256:e8f0a8582b906b9e964ccaa4cf5b567c48d5663afa1a08c44e58910b94c7dd8c))
  - Then the [values.yaml](app/service-a/deploy-config/production/values.yaml) under `production` folder will have the `tag` entry updated with this new tag.

For any other commit in any other branch, we have the flow:
- The [PR Checks](.github/workflows/pr-check.yaml) will be called.
- It will check the unittests for both applications

All these workflows use tokens and secrets provided directly from Github. I created a [Github's deployment environment](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments), and added all secrets used by the workflows over there.
Github will guarantee the encryption of these datas and the anonymization of their contents when logging them on the pipelines. 

### Continuous Delivery

I'm using [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) as the CD tool. The ArgoCD will take the application manifests for these apps, in each environment
and deploy them into the Kubernetes cluster.
- **developer**:
  - [service-a](app/service-a/deploy-config/developer/application.yaml)
  - [service-b](app/service-b/deploy-config/developer/application.yaml)
- **production**:
  - [service-a](app/service-a/deploy-config/production/application.yaml)
  - [service-b](app/service-b/deploy-config/production/application.yaml)

When deployed in the cluster, the ArgoCD components will take the [Helm](https://helm.sh/) chart that I created ([application helm chart](backstage/cd/helm/charts/app)) to deploy the app.
In this chart we have three Kubernetes components, namely [Deployment](backstage/cd/helm/charts/app/templates/deployment.yaml), [Service](backstage/cd/helm/charts/app/templates/service.yaml) and [Ingress](backstage/cd/helm/charts/app/templates/ingress.yaml).

Also, in the ArgoCD application files, we have the `source` section where we specify the ArgoCD's watcher. For example:
```yaml
    path: backstage/cd/helm/charts/app
    repoURL: https://github.com/victoramsantos/offerfit.git
    targetRevision: HEAD
    helm:
      valueFiles:
        - values.yaml
        - /app/service-a/deploy-config/production/values.yaml
```
In this case we have that for every change in the `repoURL`, ArgoCD will automatically reapply the Application Chart with its default [value.yaml](backstage/cd/helm/charts/app/values.yaml) but overriding it to the specific environment of that application (`developer` or `production`).

In order to segregate the two environments I'm creating two different namespaces, namely `developer` and `production`.

### Kubernetes Cluster

For the Kubernetes cluster provision, I'm using the [kind](https://kind.sigs.k8s.io/), which creates a Kubernetes' node as docker container.
In order to provision the nodes, I'm using the [cluster-config.yaml](backstage/infra/kind-resources/cluster-config.yaml) manifest.
On this manifest, I'm declaring three nodes, one as control-plane and two as workers. Each of these worker nodes has label called `tier` and the value `backend` and `backstage` respectively.
In the `backend` node, I'm deploying all the applications and on the `backstage` node, I'm deploying the ArgoCD, Nginx-Ingress and Metric Server pods.
This was an architecture decision to better manage the resources (CPU and Memory) when deploying this project locally.

The CI workflows run as serverless inside the Github repository, so we don't need to provision it. 
However, for the ArgoCD I'm using Helm to install it with the [argocd-values.yaml](backstage/cd/argo/manifests/argocd-values.yaml).
This is a very contained version of ArgoCD only for this project, and not ready for production.

### Auxiliary tools

I'm using the [Metric Server](https://github.com/kubernetes-sigs/metrics-server) to help checking the CPU and Memory consumption of the pods in the cluster.
It was deployed using helm and with the [metrics-server-values.yaml](backstage/infra/kubernetes/metrics-server-values.yaml).

I also deployed the [Nginx-Ingress](https://github.com/kubernetes/ingress-nginx) using helm with the [ingress-controller-values.yaml](backstage/infra/kubernetes/ingress-controller-values.yaml).
With this ingress all the application and the [ArgoCD web UI](backstage/cd/argo/manifests/argocd-ingress.yaml) can be accessed using one of the URLs:
- http://dev.service-a.offerfit.local
- http://dev.service-b.offerfit.local
- http://production.service-a.offerfit.local
- http://production.service-b.offerfit.local
- http://argocd.offerfit.local

In order to this work, it's necessary to update the `/etc/hosts` from your local, running the command:
```shell
sudo echo "127.0.0.1 dev.service-a.offerfit.local dev.service-b.offerfit.local prod.service-a.offerfit.local prod.service-b.offerfit.local argocd.offerfit.local" | sudo tee -a /etc/hosts   
```

## Running the Project

### Requirements

- [Helm](https://helm.sh/docs/intro/install/) - v3.16.4+
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) - v0.24.0+
- Some container runtime like [Docker](https://docs.docker.com/engine/install/) or [Colima](https://github.com/abiosoft/colima)
- [Kubectl](https://kubernetes.io/docs/reference/kubectl/)

### Bootstrap

I created the [big-ben.sh](bootstrap/big-ben.sh) script that deploys everything that we need to provision this test.
The script follows the flow:
- Setup k8s cluster (`kind-offerfit`)
- Setup CD with ArgoCD
- Setup nginx-ingress
- Install metric-server
- Wait for ArgoCD and Ingress components start
- Deploy the ArgoCD Application for both apps
- Add ingresses
- Print the ArgoCD admin's password

You'll need to update the `LOCAL_HOME` variable of this script with the root path of this project.

After the script has finished, the latest version of the applications will be deployed by ArgoCD in to the kind's kubernetes cluster just created.

### Testing

Now that everything is deployed, you can test it by changing anything under the paths:
- `app/service-a/src/*`
- `app/service-b/src/*`

And creating a pull-request to the repository. This will trigger the CIs pipelines and deploy the change into the `developer` environment.
In case you want to push the change to the `production` environment, you can create a new release in the Github's project.

In order to check the ArgoCD web UI, the `big-ben.sh` scripts outputs the admin's password for the `admin` user.

### Destroying

We can destroy everything just removing the kubernetes cluster. The [destroy.sh](bootstrap/destroy.sh) script does it.
Also, remember to remove the entries created on the `/etc/hosts`. 
