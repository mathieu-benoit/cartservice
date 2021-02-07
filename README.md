This `cartservice` is isolating one of the app for the `Online Boutique` repo from Google (aka [GoogleCloudPlatform/microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo)). The intent is here is to illustrate advanced concepts with a .NET app on Kubernetes.

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

_Note: this repo, as my playground for demo purposes, is also a good place for me to test things and give back to the original repo [by contributing to it](https://github.com/GoogleCloudPlatform/microservices-demo/pulls?q=is%3Apr+author%3Amathieu-benoit)._