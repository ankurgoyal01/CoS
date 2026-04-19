---
service: "deal"
title: "Asset Build and Deploy"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "asset-build-deploy"
flow_type: batch
trigger: "Code merge to main branch in CI/CD pipeline"
participants:
  - "Jenkins"
  - "Webpack"
  - "Docker"
  - "Container Registry"
  - "Kubernetes GKE"
  - "dealWebApp"
architecture_ref: "dynamic-continuum-asset-build-deploy"
---

# Asset Build and Deploy

## Summary

The asset build and deploy flow is the CI/CD pipeline process that compiles deal page static assets, packages the service into a Docker container, and deploys it to Kubernetes GKE. Webpack 4 compiles and bundles JavaScript and CSS assets; the resulting artifacts are baked into the Docker image. Deployments run across two production regions (us-central1 and eu-west-1) using napistrano for orchestration.

## Trigger

- **Type**: schedule / event (CI/CD)
- **Source**: Code merge to main branch in the deal service repository; manual dispatch for hotfix deploys
- **Frequency**: Per code merge (on-demand); hotfix as needed

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Jenkins | CI/CD orchestrator — runs pipeline stages | N/A (infrastructure) |
| Webpack | Compiles and bundles deal page static assets | N/A (build tool) |
| Docker | Builds container image containing compiled assets and Node.js app | N/A (infrastructure) |
| Container Registry | Stores versioned Docker images | N/A (infrastructure) |
| Kubernetes GKE | Receives and runs updated container; performs rolling update | N/A (infrastructure) |
| Deal Web App | The running service being updated | `dealWebApp` |

## Steps

1. **Trigger Pipeline**: Code merge to main branch triggers Jenkins pipeline.
   - From: `Developer / CI trigger`
   - To: `Jenkins`
   - Protocol: Webhook / Git event

2. **Install Dependencies**: Jenkins runs `npm install` to restore Node.js dependencies.
   - From: `Jenkins`
   - To: `npm`
   - Protocol: Shell command

3. **Build Static Assets**: Jenkins runs `webpack` (Webpack 4.46.0) to compile and bundle all deal page JS and CSS assets into the build output directory.
   - From: `Jenkins`
   - To: `Webpack`
   - Protocol: Shell command

4. **Run Tests**: Jenkins executes the test suite to validate the build.
   - From: `Jenkins`
   - To: Test runner
   - Protocol: Shell command

5. **Build Docker Image**: Jenkins runs `docker build` to create a container image containing the Node.js application and compiled Webpack assets.
   - From: `Jenkins`
   - To: `Docker`
   - Protocol: Shell command

6. **Push to Registry**: Jenkins pushes the tagged Docker image to the container registry.
   - From: `Jenkins`
   - To: `Container Registry`
   - Protocol: Docker registry API

7. **Deploy to Staging**: napistrano deploys the new image to the staging Kubernetes cluster via rolling update.
   - From: `Jenkins / napistrano`
   - To: `Kubernetes GKE (staging)`
   - Protocol: Kubernetes API

8. **Deploy to Production (US)**: napistrano deploys the new image to the us-central1 production GKE cluster via rolling update (min 12 / max 150 replicas).
   - From: `Jenkins / napistrano`
   - To: `Kubernetes GKE (us-central1)`
   - Protocol: Kubernetes API

9. **Deploy to Production (EU)**: napistrano deploys the new image to the eu-west-1 production GKE cluster via rolling update (min 8 / max 50 replicas).
   - From: `Jenkins / napistrano`
   - To: `Kubernetes GKE (eu-west-1)`
   - Protocol: Kubernetes API

10. **Serve Updated Assets**: New `dealWebApp` pods serve `GET /deals/assets/:file` requests from the freshly compiled Webpack bundle.
    - From: `dealWebApp`
    - To: `Browser / Mobile App`
    - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Webpack build failure | Pipeline fails; no Docker image built; deploy aborted | Previous version continues running; developer notified |
| Test suite failure | Pipeline fails; deploy aborted | Previous version continues running |
| Docker push failure | Pipeline fails; deploy aborted | Previous version continues running |
| Kubernetes rolling update failure | Rollback to previous image version | Previous stable version restored |

## Sequence Diagram

```
Developer -> Jenkins: code merge to main (pipeline trigger)
Jenkins -> npm: npm install
Jenkins -> Webpack: webpack build (compile JS/CSS assets)
Webpack --> Jenkins: compiled assets in build/
Jenkins -> TestRunner: run test suite
TestRunner --> Jenkins: test results (pass/fail)
Jenkins -> Docker: docker build (Node.js app + assets)
Docker --> Jenkins: image built
Jenkins -> ContainerRegistry: docker push (tagged image)
Jenkins -> napistrano: deploy to staging GKE
napistrano -> KubernetesGKE: rolling update (staging)
Jenkins -> napistrano: deploy to production us-central1
napistrano -> KubernetesGKE: rolling update (us-central1, 12-150 replicas)
Jenkins -> napistrano: deploy to production eu-west-1
napistrano -> KubernetesGKE: rolling update (eu-west-1, 8-50 replicas)
KubernetesGKE --> dealWebApp: new pods serving updated assets
```

## Related

- Architecture dynamic view: `dynamic-continuum-asset-build-deploy`
- Related flows: [Deal Page Load](deal-page-load.md)
