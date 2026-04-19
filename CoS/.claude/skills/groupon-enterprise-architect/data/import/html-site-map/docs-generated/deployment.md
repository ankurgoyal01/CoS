---
service: "html-site-map"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging-us-central1", "staging-us-west-2", "production-us-central1", "production-eu-west-1", "production-us-west-1"]
---

# Deployment

## Overview

html-site-map is a containerized Node.js application deployed to Groupon's Conveyor Cloud platform (Kubernetes). It runs across two cloud providers (GCP and AWS) in multiple geographic regions to serve both North American and EMEA user traffic. Deployments are managed through the `napistrano` toolchain, triggered via the Deploybot UI. Canary deployments are supported (`harnessCanaryCompatible: true`). mTLS is enforced at the Hybrid Boundary for all service ingress and egress.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` in repository root; base image `docker-conveyor.groupondev.com/conveyor/alpine-node16.15.0:2022.05.23-15.21.45-588d07d` |
| Orchestration | Kubernetes (Conveyor Cloud) | Helm + krane managed by napistrano; manifests in `.deploy-configs/*.yml` |
| Load balancer | Hybrid Boundary (HB) | mTLS ingress/egress; DNS alias `html-site-map.{production|staging}.service` |
| CDN | Groupon CDN | `www<1,2>.grouponcdn.com` (prod) / `staging<1,2>.grouponcdn.com` (staging) for static assets |
| Log shipping | Filebeat → Kafka → ELK | Filebeat sidecar ships `steno.log.*` to Kafka; index `steno` |
| Metrics | Telegraf → InfluxDB → Wavefront | Standard Measurement Architecture; dashboard at https://groupon.wavefront.com/dashboard/html-site-map |

## Environments

| Environment | Purpose | Cloud / Region | VIP |
|-------------|---------|----------------|-----|
| staging-us-central1 | Staging (North America) | GCP / us-central1 | `html-site-map.staging.stable.us-central1.gcp.groupondev.com` |
| staging-us-west-2 | Staging (EMEA) | AWS / us-west-2 | `html-site-map.staging.stable.us-west-2.aws.groupondev.com` |
| production-us-central1 | Production (North America) | GCP / us-central1 | `html-site-map.prod.us-central1.gcp.groupondev.com` |
| production-eu-west-1 | Production (EMEA) | AWS / eu-west-1 | `html-site-map.prod.eu-west-1.aws.groupondev.com` |
| production-us-west-1 | Production (US West legacy) | AWS / us-west-1 | `html-site-map.prod.us-west-1.aws.groupondev.com` |

Hybrid Boundary DNS aliases accessible to internal services:
- `html-site-map.production.service`
- `html-site-map.staging.service`

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI)
- **Config**: `Jenkinsfile` in repository root
- **Trigger**: Merge to `main` branch triggers CI build; version bump by nlm creates a deployable artifact

### Pipeline Stages

1. **Build**: `npm ci` installs dependencies; `npm run dist-assets` (Webpack production build) bundles static assets
2. **Test**: `npm test` runs lint (`eslint`, `l10nlint`) + unit tests (mocha + c8 coverage) + integration tests
3. **Artifact creation**: Docker image built and pushed to `docker-conveyor.groupondev.com/seo/html-site-map`
4. **Staging deploy**: Authorized via Deploybot — `staging-us-central1` (NA) or `staging-us-west-2` (EMEA)
5. **Production promotion**: Promoted from staging via Deploybot after staging validation — EMEA first (`production-eu-west-1`), then NA (`production-us-central1`)
6. **Rollback**: Available via Deploybot "ROLLBACK" button or `npx nap --cloud rollback {env} {region}`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Production: min 1 (EU/GCP), min 2 (AWS us-west-1), max 3–5 depending on region |
| Horizontal (staging) | Kubernetes HPA | Staging: min 1, max 3 |
| Memory | Kubernetes resource limits | See Resource Requirements table below |
| CPU | Kubernetes resource requests | 1000m request (main container) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1000m | Not set (unbounded by config) |
| Memory (main) — GCP us-central1 / EU | 1024Mi | 2048Mi |
| Memory (main) — AWS us-west-1 | 1536Mi | 3072Mi |
| CPU (filebeat sidecar) | 400m | 750m |
| Memory (filebeat sidecar) | 100Mi | 200Mi |
| CPU (logstash sidecar) | 400m | 750m |

> Disk: Not applicable — stateless application; no persistent volumes configured.
