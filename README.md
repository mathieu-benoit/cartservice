![ci](https://github.com/mathieu-benoit/cartservice/workflows/ci/badge.svg?branch=main)

This `cartservice` is isolating one of the apps for the `Online Boutique` repo from Google (aka [GoogleCloudPlatform/microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo)). The intent here is to illustrate advanced concepts with this .NET app on Kubernetes.

This app has those specifications:
- Is a .NET 5
- Has `Dockerfile` for Linux
- Is a `gRPC` endpoint
- Talks to `redis`

Here are some differences you will find in this current repo:
- `.github/dependabot.yml`
- Unprivilege container in `Dockerfile`
- Unit tests run in `Dockerfile`
- Advanced tests and controles in GitHub actions: `.github/workflows/ci.yaml`
- Container pushed in Google Artifact Registry

_Note: this repo, as my playground for demo purposes, is also a good place for me to test things and give back to the original repo [by contributing to it](https://github.com/GoogleCloudPlatform/microservices-demo/pulls?q=is%3Apr+author%3Amathieu-benoit)._

## Build and run locally

```
cd src
docker build -t cartservice .
docker run -d -p 7070:7070 cartservice

# Run it witout privileges
docker run -p 7070:7070 \
  --network host \
  --read-only \
  --cap-drop=ALL \
  --user=1000 \
  cartservice
```

FIXME: add `redis`.

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