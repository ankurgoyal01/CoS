---
service: "web-config"
title: "CI/CD Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "cicd-pipeline"
flow_type: batch
trigger: "Push to master or release branch (or branch matching *-publish$) in GitHub Enterprise"
participants:
  - "continuumWebConfigService"
  - "githubEnterprise"
architecture_ref: "components-web-config"
---

# CI/CD Pipeline

## Summary

The CI/CD pipeline runs on every push to the `master` or `release` branch (and `*-publish$` branches). It builds environment-tagged Docker images containing the generated nginx configuration for `uat`, `staging`, and `production`; validates each image by running `nginx -t`; publishes images to the internal Docker registry; and then updates image tags in the `routing-deployment` Kubernetes manifest repository, triggering rolling updates across all regional clusters.

## Trigger

- **Type**: push / merge
- **Source**: Push to `master` or `release` branch in the `routing/web-config` GitHub Enterprise repository (PR builds run Build and Test only — no publish or deploy)
- **Frequency**: On every qualifying push; typically once or a few times per day

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Jenkins (java-pipeline-dsl) | Orchestrates all pipeline stages | `continuumWebConfigService` (CI tooling) |
| Docker Compose / Docker | Builds and tests config images; pushes to registry | `continuumWebConfigService` (build tooling) |
| docker-conveyor.groupondev.com | Internal Docker image registry | `continuumWebConfigService` (external registry) |
| routing-deployment repository | Kubernetes deployment manifest repository receiving image tag updates | `githubEnterprise` |

## Steps

1. **Prepare**: Computes `version = {YYYY.MM.DD_HH.MM}_{short_sha}` from the current timestamp and Git short SHA; determines `imageName = routing/web-config`; evaluates `shouldBePublished` (true only for non-PR builds on `master`/`release`/`*-publish$`)
   - From: Jenkins
   - To: Jenkins workspace
   - Protocol: direct

2. **Build config images**: Runs `docker-compose -f .ci/docker-compose.yml build routing-config-uat routing-config-staging routing-config-production`; each service builds the `Dockerfile` with `ARG ENV={uat|staging|production}` which copies `conf/nginx/k8s/{env}/` and `data/{env}/rewrites/` into `/var/conf` of a busybox image
   - From: Jenkins
   - To: Docker daemon
   - Protocol: direct (docker-compose)

3. **Start certificate container**: Starts the certificate sidecar (`docker-compose up -d certificate_container`) to populate the `certs-dir` shared volume with TLS credentials needed for nginx validation
   - From: Jenkins
   - To: Docker daemon
   - Protocol: direct (docker-compose)

4. **Validate each environment's config (nginx -t)**: Runs each `routing-config-{env}` container to confirm config files are present in the volume; then runs the `nginx-{env}` service (`docker.groupondev.com/routing/nginx:1.23.2`) with `nginx -t -c /var/groupon/nginx/conf/main.conf` to validate the generated config syntax
   - From: Jenkins
   - To: nginx container
   - Protocol: direct (docker-compose run)

5. **Publish images** (releasable branches only): Pushes all three environment images to `docker-conveyor.groupondev.com/routing/web-config:{uat|staging|production}_{version}` using Docker Compose push
   - From: Jenkins
   - To: docker-conveyor.groupondev.com
   - Protocol: HTTPS (Docker registry API)

6. **Clone routing-deployment repo**: Clones `github.groupondev.com:routing/routing-deployment` using the `svcdcos-ssh` Jenkins SSH credential
   - From: Jenkins
   - To: `githubEnterprise`
   - Protocol: Git (SSH)

7. **Update image tags with kustomize**: Runs the `update_deployment` Docker container (kustomize v1.0.11); executes `update_deployment.sh` which calls `kustomize edit set imagetag` for each environment overlay:
   - `base` → `uat_{version}` (UAT)
   - `overlays/routing-service-staging-{region}` → `staging_{version}` (4 staging regions)
   - `overlays/routing-service-production-{region}` → `production_{version}` (4 production regions: us-west-1, eu-west-1, us-central1, europe-west1)
   - From: Jenkins (kustomize container)
   - To: routing-deployment working tree
   - Protocol: direct (kustomize CLI)

8. **Commit and push deployment update**: Commits the image tag changes to `routing-deployment/master` with message `Updating web-config_version to {version}`; pushes to origin
   - From: Jenkins
   - To: `githubEnterprise`
   - Protocol: Git (SSH)

9. **Tag for regional deployment**: Creates and pushes four Git tags to trigger regional rolling updates: `eu_deploy-{version}`, `us_deploy-{version}`, `gcp-eu_deploy-{version}`, `gcp-us_deploy-{version}`
   - From: Jenkins
   - To: `githubEnterprise`
   - Protocol: Git (SSH)

10. **Cleanup**: Docker Compose `down` is always run in the post-always step to remove containers and volumes regardless of build outcome
    - From: Jenkins
    - To: Docker daemon
    - Protocol: direct (docker-compose)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Docker build fails | Jenkins stage fails; post-always cleanup still runs | No images published; deploy not triggered |
| `nginx -t` validation fails | Docker Compose run exits non-zero; Jenkins stage fails | No images published; operator must fix the template/data issue |
| Image push to registry fails | Jenkins Publish stage fails | Images not available; deploy not triggered |
| kustomize update or git push fails | Jenkins stage fails | Existing deployment manifests unchanged; current routing pods remain at previous version |
| PR build (shouldBePublished = false) | Publish and Deploy stages are skipped via `when { equals }` | Only Build and Test run; no side effects on production |

## Sequence Diagram

```
GitHub Enterprise -> Jenkins: webhook (push to master)
Jenkins -> Docker daemon: docker-compose build routing-config-{uat,staging,production}
Jenkins -> Docker daemon: docker-compose up -d certificate_container
Jenkins -> Docker daemon: docker-compose run routing-config-{env} (verify files)
Jenkins -> Docker daemon: docker-compose run nginx-{env} (nginx -t)
nginx container --> Jenkins: validation result (exit 0 or non-zero)
Jenkins -> docker-conveyor.groupondev.com: docker-compose push routing-config-{uat,staging,production}
Jenkins -> githubEnterprise: git clone routing/routing-deployment
Jenkins -> Docker daemon: docker-compose run update_deployment (kustomize edit set imagetag)
Jenkins -> githubEnterprise: git commit + git push routing-deployment/master
Jenkins -> githubEnterprise: git tag eu_deploy-{version}; git push
Jenkins -> githubEnterprise: git tag us_deploy-{version}; git push
Jenkins -> githubEnterprise: git tag gcp-eu_deploy-{version}; git push
Jenkins -> githubEnterprise: git tag gcp-us_deploy-{version}; git push
Jenkins -> Docker daemon: docker-compose down (cleanup)
```

## Related

- Architecture component view: `components-web-config`
- Related flows: [Config Generation](config-generation.md), [Config Deployment](config-deployment.md)
