---
service: "file-transfer"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging", "production"]
---

# Deployment

## Overview

File Transfer Service runs on Google Cloud Platform (GCP) as a set of Kubernetes resources: one always-on `worker` Deployment (for REPL and console access) and two `CronJob` objects (`getaways` and `unprocessed`). The container image is built by Jenkins using a two-stage Dockerfile (Leiningen builder + runtime layer) and deployed via Deploybot through Helm/krane into SOX-scoped namespaces. Production deploys are gated through the `sox-inscope` GitHub organisation.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `.ci/Dockerfile`; two-stage build — Leiningen 2.7.1 builder + runtime |
| Orchestration | Kubernetes (GCP) | Helm charts `cmf-java-worker` v3.91.2 and `cmf-generic-cron-job` v3.91.2 |
| Image registry | Docker Conveyor | `docker-conveyor.groupondev.com/sox_inscope/file_transfer` |
| Deploy tool | krane | Applied via `deploy-production.sh` / `deploy-staging.sh` |
| Load balancer | None | No inbound traffic; service has no HTTP API |
| Log shipping | Filebeat + Kafka | Kafka endpoint: `kafka-elk-broker-production.snc1`; source types: `file-transfer_cronjob`, `file-transfer_worker` |

## Environments

| Environment | Purpose | Region | Namespace | URL |
|-------------|---------|--------|-----------|-----|
| staging | Pre-production testing | GCP `us-central1` | `file-transfer-staging-sox` | — |
| production | Live production workload | GCP `us-central1` | `file-transfer-production-sox` | VIP: `file-transfer.us-central1.conveyor.prod.gcp.groupondev.com` |

> A `us-west-1` deployment config also exists under `.meta/deployment/cloud/components/worker/` but is not included in the active deploy scripts.

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: Push to releasable branches (`staging` in `finance-engineering` org; `master` in `sox-inscope` org)

### Pipeline Stages

1. **Build**: `docker-compose -f .ci/docker-compose.yml build` — compiles uberjar inside Docker container
2. **Test**: `docker-compose -f .ci/docker-compose.yml run test` — runs Clojure tests against a containerised MySQL instance
3. **Release**: Docker image tagged and pushed to Docker Conveyor registry
4. **Deploy (staging)**: `deploy-staging.sh staging-us-central1` via Deploybot — requires "Authorize" button in Deploybot UI
5. **Deploy (production)**: `deploy-production.sh production-us-central1` via Deploybot — triggered from `sox-inscope/master` only

## CronJob Schedules

| CronJob | Schedule (UTC) | Command |
|---------|---------------|---------|
| `getaways` | `30 0 */1 * *` (daily at 00:30) | `run-job.sh sync-files getaways_booking_files` |
| `unprocessed` | `0 1 */1 * *` (daily at 01:00) | `run-job.sh check-jobs _` |

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Worker replicas | Manual (normally 0; scaled to 1 for console access) | `minReplicas: 1`, `maxReplicas: 1`; `hpaTargetUtilization: 100` |
| CronJob concurrency | Single pod per scheduled run | Managed by `cmf-generic-cron-job` Helm chart |

## Resource Requirements

### CronJob pods

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 200m | 500m |
| Memory | 500Mi | 1000Mi |

### Worker pod

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 100m | 700m |
| Memory | 1Gi | 2Gi |

## Network Policy

Egress from all pods is restricted to:

| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SFTP connections to partner servers |
| 61613 | TCP | STOMP connections to the messagebus |
| 3306 | TCP | MySQL connections to `file_transfer` database |
