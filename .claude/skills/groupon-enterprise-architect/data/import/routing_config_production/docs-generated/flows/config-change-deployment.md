---
service: "routing_config_production"
title: "Config Change and Deployment"
generated: "2026-03-03"
type: flow
flow_name: "config-change-deployment"
flow_type: synchronous
trigger: "Pull request merged to master branch"
participants:
  - "Developer"
  - "GitHub Enterprise (github.groupondev.com)"
  - "Jenkins CI"
  - "routing-config-ci Docker container"
  - "render_templates.py (Jinja2)"
  - "grout Gradle plugin"
  - "docker-conveyor.groupondev.com (Docker registry)"
  - "routing-deployment Git repository"
  - "Kustomize (bitlayer/kustomize)"
  - "Kubernetes routing-service pods"
  - "On-prem routing app nodes"
architecture_ref: "dynamic-routingConfigProduction"
---

# Config Change and Deployment

## Summary

This flow covers the complete lifecycle of a routing config change: from a developer authoring a Flexi DSL rule change, through PR review, automated CI validation, Docker image build, registry publish, and final deployment to all production routing infrastructure. The pipeline handles both Kubernetes-based cloud regions and legacy on-premises data centers. On success, routing-service nodes load the new config and begin routing traffic accordingly.

## Trigger

- **Type**: api-call (GitHub webhook to Jenkins)
- **Source**: Merge of a pull request to the `master` (or `release`) branch on `github.groupondev.com`
- **Frequency**: On-demand (per routing config change)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Developer | Authors Flexi rule changes, runs pre-merge validation, opens PR | — |
| GitHub Enterprise | Hosts source repo, triggers Jenkins via webhook, receives deploy comments | — |
| Jenkins CI | Orchestrates all pipeline stages; node label `dind_2gb_2cpu` | — |
| `routing-config-ci:0.4.0` Docker container | Provides Java 1.8 + Gradle environment for validation | — |
| `render_templates.py` | Renders Jinja2 Flexi templates before validation | `routingConfigProduction` |
| `grout` Gradle plugin | Validates compiled Flexi DSL config | `routingConfigProduction` |
| `docker-conveyor.groupondev.com` | Stores and serves versioned routing config Docker images | — |
| `routing-deployment` Git repository | Holds Kustomize overlays; receives image tag updates and deploy Git tags | — |
| `kustomize` (`bitlayer/kustomize:v1.0.11`) | Updates image tags in Kustomize overlays for four cloud environments | — |
| Kubernetes routing-service pods | Pull updated Docker image and apply new routing config | — |
| On-prem app nodes (`routing-app[1-10].snc1/sac1/dub1`) | Receive config tarball via SSH and hot-reload | — |

## Steps

1. **Author Flexi change**: Developer edits one or more `.flexi` files under `src/applications/` and commits to a feature branch.
   - From: `Developer`
   - To: `GitHub Enterprise`
   - Protocol: Git push

2. **Run pre-merge validation**: Developer executes `./bin/check-routes <test-URLs>` to verify route resolution and includes output in the PR description.
   - From: `Developer`
   - To: `api-proxy-cli` (Docker)
   - Protocol: Docker exec / local

3. **CI Prepare stage**: Jenkins clones the repository, computes version string (`<YYYY.MM.DD_HH.MM>_<short-sha>`), and runs `docker-compose run test python render_templates.py` to apply Jinja2 template rendering to all `.flexi` files.
   - From: `Jenkins CI`
   - To: `render_templates.py` (inside `routing-config-ci` container)
   - Protocol: Docker Compose exec

4. **CI Test stage**: Jenkins runs `docker-compose run test` (which executes `./gradlew validate`) to compile and validate the full Flexi config via the `grout` plugin.
   - From: `Jenkins CI`
   - To: `grout` Gradle plugin (inside `routing-config-ci` container)
   - Protocol: Docker Compose exec

5. **CI Publish stage** (releasable branch only): Jenkins builds the Docker image tagged `docker-conveyor.groupondev.com/routing/routing-config:production_<version>` from the `Dockerfile` (BusyBox + `/var/conf`) and pushes it to the internal registry.
   - From: `Jenkins CI`
   - To: `docker-conveyor.groupondev.com`
   - Protocol: Docker build + push / HTTPS

6. **Update deployment repo**: Jenkins clones `routing-deployment`, runs `update_deployment.sh` using the `kustomize` container to set the new image tag in all four cloud overlay directories, commits, and pushes to `master`.
   - From: `Jenkins CI` / `kustomize` container
   - To: `routing-deployment` Git repository
   - Protocol: Git / SSH

7. **Apply deploy Git tags**: Jenkins applies `eu_deploy-<version>`, `us_deploy-<version>`, `gcp-eu_deploy-<version>`, and `gcp-us_deploy-<version>` tags to the `routing-deployment` repo and pushes them. These tags trigger the downstream Kubernetes deployment pipeline.
   - From: `Jenkins CI`
   - To: `routing-deployment` Git repository
   - Protocol: Git / SSH

8. **Kubernetes pods roll out new image**: The routing-service Kubernetes deployments in all four regions detect the updated image tag via the deploy tags and perform a rolling update.
   - From: Kubernetes deployment pipeline
   - To: Routing-service pods (`routing-service-production-us-west-1`, `-eu-west-1`, `-us-central1`, `-europe-west1`)
   - Protocol: Kubernetes rolling update / Docker pull

9. **Post-deploy PR comment**: Jenkins (via `build.gradle` `update_pull_request_thread()`) posts a comment to the originating pull request: "Deployed to production successfully. Please verify."
   - From: `Jenkins CI` (Groovy script in `build.gradle`)
   - To: `GitHub Enterprise` API (`https://github.snc1/api/v3/repos/routing/routing-config-production/issues/<pr_id>/comments`)
   - Protocol: HTTPS REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Flexi DSL syntax error | `./gradlew validate` exits non-zero; CI Test stage fails | Pipeline halts; no image is built or pushed; existing config remains in effect |
| Docker push failure | Jenkins Publish stage fails | Pipeline halts; deployment repo is not updated; existing config remains in effect |
| `routing-deployment` clone/push failure | Jenkins deploy stage fails | Kubernetes overlays are not updated; existing running pods continue serving traffic |
| On-prem app node SSH unreachable | Gradle SSH task throws exception | Deploy to that specific node fails; other nodes may still receive updated config |
| Emergency lock file exists | Gradle deploy task throws `GradleException("Emergency lock file exists")` | Normal deploy aborted; must resolve lock before next standard deploy |
| PR comment post failure | `update()` executed with `ignoreError: true`-equivalent; non-blocking | Deploy still completes; PR comment is simply not posted |

## Sequence Diagram

```
Developer -> GitHub Enterprise: git push (feature branch)
Developer -> api-proxy-cli: ./bin/check-routes <URLs> (pre-merge)
Developer -> GitHub Enterprise: open pull request
GitHub Enterprise -> Developer: peer review
Developer -> GitHub Enterprise: merge to master
GitHub Enterprise -> Jenkins CI: webhook (build trigger)
Jenkins CI -> routing-config-ci container: docker-compose run python render_templates.py
routing-config-ci container -> Flexi templates: render Jinja2 templates
Jenkins CI -> routing-config-ci container: docker-compose run ./gradlew validate
routing-config-ci container --> Jenkins CI: validation pass/fail
Jenkins CI -> docker-conveyor.groupondev.com: docker build + push routing-config:production_<version>
Jenkins CI -> routing-deployment repo: git clone
Jenkins CI -> kustomize container: update_deployment.sh (set imagetag in 4 overlays)
kustomize container --> Jenkins CI: overlays updated
Jenkins CI -> routing-deployment repo: git commit + push + apply deploy tags
routing-deployment pipeline -> Kubernetes pods: rolling update with new image
Jenkins CI -> GitHub Enterprise API: POST /issues/<pr_id>/comments "Deployed to production successfully"
```

## Related

- Architecture dynamic view: `dynamic-routingConfigProduction`
- Related flows: [Route Validation (Pre-Merge)](route-validation-pre-merge.md), [Emergency Deploy](emergency-deploy.md)
