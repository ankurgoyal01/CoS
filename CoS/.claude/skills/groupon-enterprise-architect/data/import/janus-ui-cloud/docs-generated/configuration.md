---
service: "janus-ui-cloud"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, deployment-yaml]
---

# Configuration

## Overview

Janus UI Cloud is configured primarily through environment variables injected at runtime by the Kubernetes deployment manifests. Environment-specific values are defined in YAML files under `.meta/deployment/cloud/components/janus-ui/`. The service uses the `RUNNING_ENV` variable to select environment-appropriate behaviour at startup. No external config store (Consul, Vault, etc.) is referenced in the codebase.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `RUNNING_ENV` | Selects runtime environment profile (`development`, `staging`, `production`, `local`) | yes | `local` | Deployment YAML per environment |
| `NODE_ENV` | Node.js environment mode; controls Express middleware behaviour and build optimisation | yes | `development` | npm scripts / Docker entrypoint |
| `PORT` | HTTP port the Express server listens on | no | `8080` | `bin/www` (`process.env.PORT`) |
| `MALLOC_ARENA_MAX` | Tunes glibc memory arena count to prevent virtual memory explosion in containers | no | `4` | `common.yml` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flag system is in use.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/janus-ui/common.yml` | YAML | Shared Kubernetes deployment settings: image, ports, resource requests, health probes, HPA target |
| `.meta/deployment/cloud/components/janus-ui/dev-us-west-2.yml` | YAML | Dev environment overrides: AWS us-west-2, min/max replicas 1/1, `RUNNING_ENV=development` |
| `.meta/deployment/cloud/components/janus-ui/staging-us-west-2.yml` | YAML | Staging overrides: AWS us-west-2, min/max replicas 1/2, `RUNNING_ENV=staging` |
| `.meta/deployment/cloud/components/janus-ui/staging-us-central1.yml` | YAML | Staging overrides: GCP us-central1, min/max replicas 1/2, `RUNNING_ENV=staging` |
| `.meta/deployment/cloud/components/janus-ui/production-us-west-2.yml` | YAML | Production overrides: AWS us-west-2, min/max replicas 2/15, `RUNNING_ENV=production`, CPU 100m, memory 1800Mi/4Gi |
| `.meta/deployment/cloud/components/janus-ui/production-us-central1.yml` | YAML | Production overrides: GCP us-central1, min/max replicas 2/15, `RUNNING_ENV=production`, CPU 100m, memory 1800Mi/4Gi |
| `.meta/.raptor.yml` | YAML | Raptor service registration; component type `api`, archetype `java` (sic — inherited template) |
| `.service.yml` | YAML | Service portal metadata: team, SRE contacts, PagerDuty, Wavefront dashboard, dependencies |

## Secrets

> No evidence found in codebase. The `.meta/.raptor.yml` file has an empty `secret_path` field, indicating no secrets are currently configured through Raptor. Any session or proxy credentials would be injected at the platform level.

## Per-Environment Overrides

| Environment | Cloud | Region | Replicas (min/max) | Memory Limit | Notes |
|-------------|-------|--------|--------------------|-------------|-------|
| development | AWS | us-west-2 | 1 / 1 | Default | Hybrid boundary ingress/egress enabled |
| staging | AWS | us-west-2 | 1 / 2 | Default | Namespace: `janus-ui-cloud-staging` |
| staging | GCP | us-central1 | 1 / 2 | Default | VPC: `stable`; VIP: `janus-ui-cloud.staging.service.us-central1.gcp.groupondev.com` |
| production | AWS | us-west-2 | 2 / 15 | 4 Gi | CPU request: 100m |
| production | GCP | us-central1 | 2 / 15 | 4 Gi | VIP: `janus-ui-cloud.us-central1.conveyor.prod.gcp.groupondev.com` |
