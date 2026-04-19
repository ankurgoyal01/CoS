---
service: "api-proxy-config"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["dev", "staging", "production"]
---

# Deployment

## Overview

`api-proxy-config` is deployed as a containerized Java application orchestrated by Kubernetes across multiple cloud regions (AWS and GCP). The Docker image (`docker-conveyor.groupondev.com/groupon-api/api-proxy-config`) is built from the Maven assembly artifact and deployed via Helm charts (`cmf-java-api` v3.92.0 for the application, `cmf-generic-telegraf` v3.92.0 for the Telegraf metrics sidecar). Deployments are managed through DeployBot v2 using the `.deploy_bot.yml` configuration. A rolling update strategy with `maxUnavailable: 0` and `maxSurge: 25%` ensures zero-downtime deployments.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker | `docker-conveyor.groupondev.com/groupon-api/api-proxy-config` |
| Orchestration | Kubernetes | Namespaces: `api-proxy-dev`, `api-proxy-staging`, `api-proxy-production` |
| Helm chart (app) | `cmf-java-api` | Version 3.92.0, registry: `http://artifactory.groupondev.com/artifactory/helm-generic/` |
| Helm chart (telemetry) | `cmf-generic-telegraf` | Version 3.92.0, same registry |
| Deployment tool | DeployBot v2 | Config: `.deploy_bot.yml`; deploy image: `deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0` |
| Kubernetes apply tool | `krane` | Used in `deploy.sh` with `--global-timeout` per environment |
| Service discovery | HybridBoundary | RRDNS + HTTP/2 upstream; domains: `api-proxy--internal-us` (NA), `api-proxy--internal-eu` (EMEA) |
| Ingress | HTTPS ingress | Inbound port 9443; `httpsPort: 8443`; `httpsIngress.enabled: true` |
| Load balancer | Kubernetes ServiceLB | `enableGateway: true` (common); `enableGateway: false` for GCP staging/production (uses LoadBalancer directly) |
| Metrics sidecar | Telegraf + Jolokia | Jolokia port 8778; `telegrafJolokia.enabled: true` |
| Log shipping | Filebeat | Source type `api_proxy`; log dir `/app/log`; file `application.log`; ships to Kafka |
| VPA | Vertical Pod Autoscaler | `enableVPA: true` |

## Environments

| Environment | Purpose | Region / Cloud | Kubernetes Namespace | Config Path |
|-------------|---------|----------------|---------------------|-------------|
| `dev` | Developer testing | GCP us-central1 | `api-proxy-dev` | `conf/staging-us-central1/mainConf.json` |
| `staging` (NA) | Pre-production validation | GCP us-central1 | `api-proxy-staging` | `conf/staging-us-central1/mainConf.json` |
| `staging` (EMEA) | Pre-production validation | GCP europe-west1 | `api-proxy-staging` | `conf/staging-europe-west1/mainConf.json` |
| `production` (NA - AWS) | Live traffic (NA) | AWS us-west-1 | `api-proxy-production` | `conf/production-us-west-1/mainConf.json` |
| `production` (NA - GCP) | Live traffic (NA) | GCP us-central1 | `api-proxy-production` | `conf/production-us-central1/mainConf.json` |
| `production` (EMEA - AWS) | Live traffic (EMEA) | AWS eu-west-1 | `api-proxy-production` | `conf/production-eu-west-1/mainConf.json` |
| `production` (EMEA - GCP) | Live traffic (EMEA) | GCP europe-west1 | `api-proxy-production` | `conf/production-europe-west1/mainConf.json` |

## CI/CD Pipeline

- **Tool**: DeployBot v2
- **Config**: `.deploy_bot.yml`
- **Trigger**: Git tag matching per-target `tag_regex` pattern (`-v(?P<version>.*)$`); `manual: true` for most targets; `staging-us-central1` and `staging-europe-west1` are `manual: false` and auto-promote to production

### Pipeline Stages

1. **Tag**: Engineer creates a Git tag matching the target environment regex to initiate a deployment
2. **Helm template (app)**: DeployBot renders `cmf-java-api` Helm chart using `common.yml`, secrets overlay, and per-environment values
3. **Helm template (telegraf)**: DeployBot renders `cmf-generic-telegraf` Helm chart using telegraf `common.yml` and per-environment values
4. **Deploy**: `krane deploy` applies rendered manifests to the target Kubernetes namespace with environment-specific timeout (300s for dev/general, 4000s for staging/production)
5. **Promote** (staging → production): `staging-us-central1` auto-promotes to `production-us-central1`; `staging-europe-west1` auto-promotes to `production-eu-west-1`
6. **Notify**: DeployBot sends notifications on `start`, `complete`, and `override` events

### Deploy Script

`.meta/deployment/cloud/scripts/deploy.sh` invoked by DeployBot for GCP production targets:
```bash
helm3 template cmf-java-api \
  --repo http://artifactory.groupondev.com/artifactory/helm-generic/ \
  --version '3.92.0' \
  -f .meta/deployment/cloud/components/app/common.yml \
  -f .meta/deployment/cloud/secrets/cloud/<env>.yml \
  -f .meta/deployment/cloud/components/app/<env>.yml \
  --set appVersion=${DEPLOYBOT_PARSED_VERSION} \
  | krane deploy api-proxy-<env> <context> --global-timeout=300s --filenames=- --no-prune
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | HPA | Min: 2 / Max: 12 / Target CPU: 90% |
| Horizontal (production NA) | HPA | Min: 12 / Max: 100 / Target CPU: 90% |
| Horizontal (production EMEA) | HPA | Min: 12 / Max: 240 / Target CPU: 90% |
| Vertical | VPA | `enableVPA: true` — automatic right-sizing |
| Topology (production) | Topology spread constraints | Zone and node spreading, `maxSkew: 100`, `whenUnsatisfiable: ScheduleAnyway` |
| Rolling update | `maxUnavailable: 0`, `maxSurge: 25%` | Zero-downtime rolling deploy |

## Resource Requirements

### Application Container (`main`)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (dev/staging) | 300m | 2000m |
| CPU (production) | 400m | 2000m |
| Memory (dev/staging) | 2600Mi | 4Gi |
| Memory (production) | 2700Mi | 4Gi |

### Sidecar Containers

| Container | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| Envoy | 400–500m | 1000m | — | — |
| Filebeat | 250–300m | 600–650m | 200Mi | 280Mi |
| Telegraf/Jolokia | 8–300m | 30–650m | — | — |

### Port Assignments

| Port | Protocol | Purpose |
|------|----------|---------|
| 9000 | HTTP | Application HTTP / health check (`/grpn/ready`) |
| 8443 | HTTPS | Application HTTPS |
| 9001 | HTTP | Admin port |
| 8778 | HTTP | Jolokia JMX-over-HTTP (metrics) |
| 9443 | HTTPS | HTTPS ingress inbound |
