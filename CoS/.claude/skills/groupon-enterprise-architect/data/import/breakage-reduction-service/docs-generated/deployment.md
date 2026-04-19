---
service: "breakage-reduction-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production, catfood]
---

# Deployment

## Overview

BRS is containerized using Docker (Node.js 16 base image) and deployed to Kubernetes via Groupon's Conveyor Cloud platform using Napistrano for deploy config generation. It runs in both US and EMEA regions in production, with mTLS enforced by the Envoy sidecar via the Hybrid Boundary upstream. Deployments are promoted from staging to production via Deploybot after branch merges to master.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` — base: `docker-conveyor.groupondev.com/conveyor/alpine-node16.14.2:2022.03.21-16.29.25-3925f6b` |
| Orchestration | Kubernetes (Conveyor Cloud) | Napistrano-generated Helm configs in `.deploy-configs/` |
| Load balancer | Hybrid Boundary (Envoy) | Ingress and egress enabled; HB upstream configured per region |
| Logging | Filebeat → Kafka → Elasticsearch (ELK) | `steno.log.*` shipped via Filebeat sidecar; Splunk sourcetype `vex_json` |
| Metrics | Telegraf → InfluxDB → Wavefront | Standard Measurement Architecture (SMA) |
| Service mesh | mTLS Interceptor (Envoy) | `mtlsInterceptor: true`; `hbUpstream: true` |

## Environments

| Environment | Purpose | Region | URL / VIP |
|-------------|---------|--------|-----------|
| staging | Pre-production testing | us-west-1 (AWS) | `vex.staging.stable.us-west-1.aws.groupondev.com` / `vex.staging.service` |
| staging | Pre-production testing | us-west-2 (AWS) | `vex.staging.stable.us-west-2.aws.groupondev.com` |
| staging | Pre-production testing | us-central1 (GCP) | GCP staging endpoint |
| production | Live traffic | us-west-1 (AWS) | `vex.prod.us-west-1.aws.groupondev.com` / `vex.production.service` |
| production | Live traffic | eu-west-1 (AWS) | EMEA production VIP |
| production | Live traffic | us-central1 (GCP) | GCP production endpoint |
| production | Live traffic | europe-west1 (GCP) | GCP EMEA production endpoint |
| catfood | Production canary / A-B testing | us-central1 (GCP), eu-west-1 (AWS) | Uses production cloud deploy env |

## CI/CD Pipeline

- **Tool**: Jenkins (cloud-jenkins.groupondev.com) + GitHub Actions
- **Config**: `Jenkinsfile` (Jenkins pipeline), `.github/workflows/ci.yml` (GitHub Actions CI), `.github/workflows/contract_tests.yml` (Pact contract tests), `.github/workflows/on_deploy.yml` (post-deploy hooks)
- **Trigger**: Push to master / pull request / merge group

### Pipeline Stages

1. **Contract Tests**: Runs Pact consumer-driven contract tests against downstream services
2. **Lint**: ESLint check (`eslint-config-groupon`)
3. **Unit Tests**: Mocha unit tests with c8 coverage (`mocha 'modules/**/*.test.*'`)
4. **Integration Tests**: Mocha integration tests (`mocha test/integration`)
5. **Browser Tests**: Testem/Chrome browser tests (`testem ci`)
6. **Build**: webpack asset compilation
7. **Deploy (Staging)**: Deploybot triggers Napistrano deploy to staging; verified via Kibana and Wavefront
8. **Deploy (Production)**: Promoted from staging via Deploybot after manual verification

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (Staging) | Kubernetes HPA (Napistrano) | Min: 3, Max: 5 replicas |
| Horizontal (Production) | Kubernetes HPA (Napistrano) | Min: 3, Max: 12 replicas |
| Harness Canary | Canary-compatible progressive delivery | `harnessCanaryCompatible: true` |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Memory (main) | 1536Mi | 3072Mi |
| CPU (main) | 1000m | not set |
| CPU (logstash) | 400m | 750m |
| CPU (filebeat) | 400m | 750m |
| Memory (filebeat) | 100Mi | 200Mi |

Source: `.deploy-configs/production-us-west-1.yml`, `.deploy-configs/values.yaml`

## Server Process Configuration (Production)

| Setting | Value | Source |
|---------|-------|--------|
| `server.child_processes` | 7 | `config/stage/production.cson` |
| `server.max_sockets` | 100 | `config/stage/production.cson` |
| `server.port` | 8000 | `config/stage/production.cson` |
| `UV_THREADPOOL_SIZE` | 75 | `.deploy-configs/production-us-west-1.yml` |
| `NODE_OPTIONS` | `--experimental-modules --max-old-space-size=1024` | `.deploy-configs/production-us-west-1.yml` |
