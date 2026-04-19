---
service: "pact-broker"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging]
---

# Deployment

## Overview

Pact Broker is deployed as a containerized application on GCP (Google Cloud Platform) managed by Kubernetes. The Docker image is sourced from `docker-conveyor.groupondev.com/pact-foundation/pact-broker`. Deployment is orchestrated via Helm (chart: `cmf-generic-api` version `3.95.1`) and applied using `krane`. The CI/CD pipeline is driven by Jenkins using the `java-pipeline-dsl` shared library. Deployments are triggered through Deploybot.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` (FROM alpine:latest; final image: `docker-conveyor.groupondev.com/pact-foundation/pact-broker:2.135.0-pactbroker2.117.1`) |
| Orchestration | Kubernetes (GCP) | Helm chart `cmf-generic-api@3.95.1`; applied via `krane`; cluster: `gcp-stable-us-central1` |
| Deploy tooling | krane | `krane deploy pact-broker-{env} {kube-context} --global-timeout=300s` |
| Deployment UI | Deploybot | [deploybot.groupondev.com/qa/pact-broker](https://deploybot.groupondev.com/qa/pact-broker) — manual approval required for secret updates |
| Load balancer | GCP (hybrid boundary) | `hybridBoundary.isDefaultDomain: true`, `namespace: default` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | QA / integration contract testing | GCP us-central1 | Not documented in repo; see Confluence |
| production | Production contract registry | Not documented in this repo | See [QA Tribe Confluence](https://groupondev.atlassian.net/wiki/spaces/QAT/pages/82222252147/Pact+Broker+-+Infrastructure) |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push (standard branch/main pipeline)

### Pipeline Stages

1. **Docker build**: Jenkins builds the Docker image using the `dockerBuildPipeline` shared library step (`java-pipeline-dsl@latest-2`)
2. **Image push**: Built image is pushed to the Groupon container registry
3. **Deploy to staging-us-central1**: Deploybot triggers `bash .meta/deployment/cloud/scripts/deploy.sh staging-us-central1 staging pact-broker-staging`
4. **Helm template**: `helm3 template cmf-generic-api` merges secrets and app config into Kubernetes manifests
5. **krane apply**: Manifests are applied to the `pact-broker-staging` namespace on `gcp-stable-us-central1` with a 300-second timeout

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual (fixed) | `minReplicas: 2`, `maxReplicas: 2`, `hpaTargetUtilization: 100` |
| Pod Disruption | Budget enforced | `maxUnavailable: 20%` |
| Memory scaling | Disabled | `enableMemoryUtilization: false` |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 100m | No limit (`setResourceLimits.main.cpu: false`) |
| Memory | 512Mi | 1Gi (`setResourceLimits.main.memory: true`) |
| Disk | Not configured | — |

## Health Probes

| Probe | Path | Port | Initial Delay | Period | Timeout | Failure Threshold |
|-------|------|------|---------------|--------|---------|-------------------|
| Liveness | `/diagnostic/status/heartbeat` | 9292 | 30s | 15s | 5s | 3 |
| Readiness | `/diagnostic/status/heartbeat` | 9292 | 20s | 5s | 5s | 3 |

## Secrets Management

Secrets are stored in a Git submodule at `.meta/deployment/cloud/secrets` (pointing to [QA/pact-broker-secrets](https://github.groupondev.com/QA/pact-broker-secrets)). To update secrets:
1. Update the `pact-broker-secrets` repository.
2. Update the submodule reference in this repo (`git submodule update --remote .meta/deployment/cloud/secrets`).
3. Commit and push the submodule pointer update.
4. Approve the manual deployment in Deploybot.
5. Update the corresponding entry in 1Password.
