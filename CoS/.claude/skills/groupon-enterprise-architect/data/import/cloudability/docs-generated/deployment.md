---
service: "cloudability"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging", "production"]
---

# Deployment

## Overview

The Cloudability Metrics Agent is deployed as a Kubernetes Deployment to each Conveyor cluster via deploybot. The agent runs in its own namespace (`cloudability-staging` or `cloudability-production`) using the `cloudability` ServiceAccount. Deployment manifests are generated from the Cloudability SaaS API, patched by the provisioning CLI, committed to the `secrets/` submodule, and then automatically applied by deploybot on every merge to `main`. Staging clusters are promoted sequentially before production clusters are updated.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | `docker.groupondev.com/cloudability/metrics-agent:2.4` | Third-party image, mirrored to Groupon's internal registry; pinned to version 2.4 |
| Orchestration | Kubernetes | Manifest files in `secrets/conveyor-<context>.yml` |
| Deploy tooling | deploybot v2 | Config in `.deploy_bot.yml`; deploy image `docker.groupondev.com/rapt/deploy_kubernetes:v2.3.0-3.3.0-1.1.4-1.16.4` |
| Slack notifications | Slack channel `CNY6HCXBJ` (cloud-sre-testing) | Events: start, complete, override |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| `staging-us-west-1` | Staging validation | us-west-1 | - |
| `staging-us-west-2` | Staging validation | us-west-2 | - |
| `staging-us-central1` | Staging validation (GCP) | us-central1 | - |
| `staging-europe-west1` | Staging validation (GCP EMEA) | europe-west1 | - |
| `production-us-west-1` | Production | us-west-1 | - |
| `production-us-west-2` | Production | us-west-2 | - |
| `production-eu-west-1` | Production EMEA | eu-west-1 | - |
| `production-us-central1` | Production (GCP) | us-central1 | - |
| `production-europe-west1` | Production (GCP EMEA) | europe-west1 | - |

Deploybot promotion chain:
`staging-us-west-1` → `staging-us-west-2` → `staging-us-central1` → `production-us-west1` (and independently `staging-europe-west1` → `production-europe-west1`)

## CI/CD Pipeline

- **Tool**: deploybot
- **Config**: `.deploy_bot.yml`
- **Trigger**: Merge to `main` branch; also available at `https://deploybot.groupondev.com/CloudSRE/cloudability`

### Pipeline Stages

1. **Manifest Generation**: Cloud SRE runs `get_agent_config.sh` to register the cluster, fetch the manifest, and apply Groupon-specific patches
2. **Secrets Submodule Update**: Updated manifests are committed to the `secrets/` submodule (`CloudSRE/cloudability-secrets`)
3. **Main Branch Merge**: Pull request merged to `main` in the cloudability repo
4. **Deploybot Apply**: Deploybot detects the updated secrets submodule and runs `kubectl -n cloudability-<env> apply -f secrets/conveyor-<context>.yml` for each target cluster in the promotion chain
5. **Verification**: SRE verifies pod status and data flow in the Cloudability portal (data may take up to 24 hours to appear)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Single replica per cluster (Deployment) | No HPA configured |
| Memory | Fixed request and limit | Request: `1024Mi`, Limit: `1024Mi` |
| CPU | Fixed request and limit | Request: `1000m`, Limit: `1000m` |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 1000m | 1000m |
| Memory | 1024Mi | 1024Mi |
| Disk | No evidence found in codebase | - |

## Security Configuration

- Container runs as UID 1000 (`runAsUser: 1000`, `runAsNonRoot: true`)
- `allowPrivilegeEscalation: false`
- `readOnlyRootFilesystem: true` (applied by OPA policy)
- Image pull policy: `IfNotPresent` (overridden from Cloudability default `Always`)
- Readiness probe skipped via annotation: `com.groupon.conveyor.policies/skip-readiness-probe: "cloudability-metrics-agent"`

## Manual Deployment

To deploy manually without deploybot:

```bash
# Authenticate with Conveyor
kubectl cloud-elevator auth
kubectl config use-context production-us-west-2

# Dry run (client-side)
kubectl apply --dry-run=client -f secrets/conveyor-$(kubectl config current-context).yml

# Dry run (server-side)
kubectl apply --dry-run=server -f secrets/conveyor-$(kubectl config current-context).yml

# Apply
kubectl apply -f secrets/conveyor-$(kubectl config current-context).yml
```
