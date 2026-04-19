---
service: "pricing-control-center-ui"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging", "production"]
---

# Deployment

## Overview

The service is containerized (Docker, Alpine Node.js 16 base) and deployed to Google Cloud Platform (GCP) Kubernetes clusters managed by Conveyor Cloud. Deployments and rollbacks are executed via Napistrano (`npx nap --cloud deploy`) which triggers Deploybot, which applies Helm chart templates via `krane`. Harness canary-compatible deployments are enabled. mTLS is enforced via the mTLS interceptor sidecar. Hybrid Boundary provides ingress and egress routing.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` (base: `docker-conveyor.groupondev.com/conveyor/alpine-node16.16.0:2022.07.22-17.49.19-36872e1`) |
| Container registry | Conveyor CI (Groupon internal) | `docker-conveyor.groupondev.com/sox-inscope/pricing-control-center-ui` |
| Orchestration | Kubernetes (GCP) | Managed by Conveyor Cloud; Helm chart version `3.89.0` (`cmf-itier`) |
| Deployment tooling | Napistrano ^2.181.16 + Deploybot | `.deploy_bot.yml`, `.deploy-configs/` |
| Load balancer | Hybrid Boundary (HB) | Ingress and egress enabled for both environments |
| Log shipping | Filebeat → Kafka → ELK | `filebeatKafkaEndpoint` in deploy configs; logs shipped to Elasticsearch |
| Metrics | Telegraf → InfluxDB → Wavefront | `itier-instrumentation` library |
| APM | Groupon APM (enabled) | `apm.enabled: true` in deploy configs |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pre-production validation | GCP us-central1 | `https://control-center--staging.groupondev.com` / VIP: `pricing-control-center-ui.staging.service` |
| production | Live internal tool | GCP us-central1 | `https://control-center.groupondev.com` / VIP: `pricing-control-center-ui.production.service` |

Additional legacy AWS VIPs (us-west-1) are referenced in the OWNERS_MANUAL but GCP us-central1 is the current target.

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI / itier-pipeline-dsl)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main` or `staging` branch triggers automatic deploy to `staging-us-central1`. Production deploy is manual via Deploybot.

### Pipeline Stages

1. **Lint**: Runs `eslint` against all JavaScript source files (`npm run lint:js`)
2. **Unit Test**: Runs mocha unit tests with c8 coverage (`c8 mocha 'modules/**/*.test.*'`)
3. **Integration Test**: Starts memcached daemon then runs mocha integration tests (`memcached -d -u memcached && npm run test:integration`)
4. **Build Assets**: Compiles Webpack bundles in production mode (`webpack --mode=production`)
5. **Docker Build**: Builds and pushes Docker image to Conveyor CI registry
6. **Deploy to Staging**: Auto-deploys artifact to `staging-us-central1` on `main`/`staging` branch merge
7. **Promote to Production**: Manual deploy via Deploybot after staging validation; only staging-promoted artifacts are eligible

### Rollback

```
npx nap --cloud rollback staging us-central1
npx nap --cloud rollback production us-central1
```

Or via Deploybot UI: `https://deploybot.groupondev.com/sox-inscope/pricing-control-center-ui`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | min 1 / max 3 replicas |
| Horizontal (production) | Kubernetes HPA | min 2 / max 3 replicas |
| Memory | Kubernetes resource limits | Request: 1536Mi / Limit: 3072Mi |
| CPU | Kubernetes resource requests | Request: 1000m (no CPU limit on main container) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1000m | Not set |
| Memory (main) | 1536Mi | 3072Mi |
| CPU (logstash) | 400m | 750m |
| CPU (filebeat) | 400m | 750m |
| Memory (filebeat) | 100Mi | 200Mi |

Node.js heap is additionally capped at 1024 MB via `NODE_OPTIONS=--max-old-space-size=1024`.
