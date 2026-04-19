---
service: "watson-api"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

Watson API is packaged as a single Docker image (`docker-conveyor.groupondev.com/watson/watson-api`) and deployed to Kubernetes as seven independent Kubernetes deployments — one per functional component. The active component is determined by the `DEPLOY_COMPONENT` environment variable injected at pod creation. All components share the same image tag. Deployment is orchestrated via Kustomize overlays stored in `.meta/deployment/cloud/` and driven by the `deploy_bot` tool using `.deploy_bot.yml` targets.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `.ci/Dockerfile` (base: `docker.groupondev.com/jtier/dev-java11-maven:2023-12-19-609aedb`) |
| Orchestration | Kubernetes | Kustomize overlays per component and environment in `.meta/deployment/cloud/components/` |
| Load balancer | Hybrid Boundary (HB) | JTier Hybrid Boundary sidecar with `isDefaultDomain: false` on all components; each component gets a `<serviceId>--<component>` domain |
| APM | JTier APM | `apm.enabled: true` on all components |
| Log shipping | Filebeat sidecar | Logs at `/var/groupon/jtier/logs/jtier.steno.log`; `sourceType: watson-api` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| dev-us-west-1 | Development | US West 1 | Internal only |
| staging-us-central1 | Staging (GCP) | US Central 1 | Internal only |
| staging-us-west-1 | Staging | US West 1 | Internal only |
| staging-us-west-2 | Staging | US West 2 | Internal only |
| staging-europe-west1 | Staging (GCP EMEA) | Europe West 1 | Internal only |
| production-us-central1 | Production (GCP) | US Central 1 | Internal only |
| production-us-west-1 | Production | US West 1 | Internal only |
| production-us-west-2 | Production | US West 2 | Internal only |
| production-eu-west-1 | Production (EMEA) | EU West 1 | Internal only |
| production-europe-west1 | Production (GCP EMEA) | Europe West 1 | Internal only |

## CI/CD Pipeline

- **Tool**: deploy_bot (`deploy_kubernetes` v2.8.5)
- **Config**: `.deploy_bot.yml`
- **Trigger**: Manual promotion chain via deploy_bot targets; each staging environment auto-promotes to its configured `promote_to` target

### Pipeline Stages

1. **Build**: Maven build in JTier CI environment (`.ci/Dockerfile`); produces Docker image `docker-conveyor.groupondev.com/watson/watson-api:{version}`
2. **Staging deploy**: `bash ./.meta/deployment/cloud/scripts/deploy-all.sh {region} staging` deploys all seven components to the target Kubernetes cluster; individual components can be deployed with `deploy.sh {component} {region} {env}`
3. **Promote**: Staging automatically promotes to production via the `promote_to` chain in `.deploy_bot.yml`
4. **Production deploy**: Same deploy scripts target production Kubernetes contexts

**Promotion chain (example for deal-kv):**
`staging-us-central1-deal-kv` → `production-us-central1-deal-kv` → `production-us-west-1-deal-kv` → `production-us-west-2-deal-kv` → `production-eu-west-1-deal-kv`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min/Max varies by component (see [Configuration](configuration.md)) |
| Memory | Kubernetes limits | Request: 500 MiB, Limit: 500 MiB (all components) |
| CPU | Kubernetes requests | Main container: 300m request; Filebeat sidecar: 10m request / 30m limit |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 300m | Not set (limit omitted) |
| CPU (filebeat) | 10m | 30m |
| Memory (main) | 500 MiB | 500 MiB |

## Ports

| Port | Purpose |
|------|---------|
| 8080 | HTTP application port (all components) |
| 8081 | Dropwizard admin port (metrics, health, Swagger) |
| 8009 | JMX port |

## TLS / Certificate Mounting

All components (except `dealkv` and `userkv`, which use `client-certs` volume) mount TLS client certificates at `/var/groupon/certs` via `additionalVolumes` configuration. Redis mTLS and Kafka TLS use these certificates.

## Docker Image

- **Registry**: `docker-conveyor.groupondev.com`
- **Repository**: `watson/watson-api`
- **Base image**: `docker.groupondev.com/jtier/dev-java11-maven:2023-12-19-609aedb` (JTier managed, Java 11 + Maven)
- **Version scheme**: `{major-minor}.{patch}` (e.g., `1.0.{CI_build_number}`)
