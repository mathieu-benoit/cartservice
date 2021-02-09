![ci](https://github.com/mathieu-benoit/cartservice/workflows/ci/badge.svg?branch=main)

This `cartservice` is isolating one of the apps for the `Online Boutique` repo from Google (aka [GoogleCloudPlatform/microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo)). The intent here is to illustrate advanced concepts with this .NET app on Kubernetes.

_Note: this repo, as my playground for demo purposes, is also a good place for me to test things and give back to the original repo [by contributing to it](https://github.com/GoogleCloudPlatform/microservices-demo/pulls?q=is%3Apr+author%3Amathieu-benoit)._

This app has those specifications:
- Is a .NET 5
- Has `Dockerfile` for Linux
- Is a `gRPC` endpoint
- Talks to `redis`

## What's more in there?

Here are some differences you will find in this current repository which are not in the original one:
- `.github/dependabot.yml`
- Unprivilege container in `Dockerfile` (non root, etc.)
- Unit tests run in `Dockerfile`
- CI with Advanced tests and controls in GitHub actions: `.github/workflows/ci.yaml`
- Container pushed in Google Artifact Registry
- Cloud Monitoring dashboard as code in `gcloud/monitoring`

In addition to this, the deployment part for this application in Kubernetes is defined [in that other repository](https://github.com/mathieu-benoit/my-kubernetes-deployments), with some differences from the original one too:
- Memory store (redis) instead of `redis` as container
- `NetworkPolicies` (`calico`) to add more security between pods communications
- `Pod Security Context` in Kubernetes' `Deployment` manifest (non root, etc.)
- Kubernetes `Service Account` as manifest file
- Anthos Service Mesh to inject `istio-proxy` sidecar

## Build and run locally

Requirements locally:
- Docker

```
cd src
docker build -t cartservice .
docker run -d -p 6379:6379 --network host --name redis-cart redis
docker run -d -p 7070:7070 --network host --name cartservice -e REDIS_ADDR="localhost:6379" --read-only --cap-drop=ALL --user=1000 cartservice
```

## CI setup with Google Artifact Registry and GitHub actions

Requirements locally:
- `gcloud` cli, [installation](https://cloud.google.com/sdk/docs/install)
- `gh` cli, [installation](https://github.com/cli/cli#installation)

Requirements in GCP:
- GKE
- Artifact registry

Setup the service Account for GitHub actions:
```
artifactRegistryProjectId=FIXME
artifactRegistryName=FIXME
artifactRegistryLocation=FIXME

gcloud config set project $artifactRegistryProjectId

saName=gha-containerregistry-push-sa
saId=$saName@$artifactRegistryProjectId.iam.gserviceaccount.com
gcloud iam service-accounts create $saName \
    --display-name=$saName
gcloud artifacts repositories add-iam-policy-binding $artifactRegistryName \
    --location $artifactRegistryLocation \
    --member "serviceAccount:$saId" \
    --role roles/artifactregistry.writer
gcloud iam service-accounts keys create ~/tmp/$saName.json \
    --iam-account $saId

gh auth login --web
gh secret set CONTAINER_REGISTRY_PUSH_PRIVATE_KEY < ~/tmp/$saName.json
rm ~/tmp/$saName.json
gh secret set CONTAINER_REGISTRY_PROJECT_ID -b"${artifactRegistryProjectId}"
gh secret set CONTAINER_REGISTRY_NAME -b"${artifactRegistryName}"
gh secret set CONTAINER_REGISTRY_HOST_NAME -b"${artifactRegistryLocation}-docker.pkg.dev"
```

## Leverage Memorystore (Redis)

```
gcloud services enable redis.googleapis.com
gcloud redis instances create cart --size=1 --region=us-east4 --zone=us-east4-a --redis-version=redis_5_0
gcloud redis instances describe cart --region=us-east4 --format='get(host)'
# Set the `REDIS_ADDR` environment variable with that `host` IP address.
```

_Note: there is few requirements about how and where create your Memorystore instance to be able to use it with GKE, [see here for more information](https://cloud.google.com/memorystore/docs/redis/connect-redis-instance-gke)._

## Monitoring with Cloud Operations

```
gcloud monitoring dashboards create --config-from-file=gcloud/monitoring/dashboard.yaml
```