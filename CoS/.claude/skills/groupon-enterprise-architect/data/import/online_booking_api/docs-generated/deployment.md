---
service: "online_booking_api"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-west-2, staging-us-central1, staging-europe-west1, production-us-central1, production-europe-west1, production-eu-west-1]
---

# Deployment

## Overview

The Online Booking API runs as a containerized Ruby on Rails application orchestrated by Kubernetes via Groupon's Conveyor Cloud platform. The Docker image is a two-stage build (builder + runtime) based on `docker.groupondev.com/ruby:2.3`. The runtime container exposes port 3000 (via nginx on port 8080 inside the cluster). The service is deployed across multiple GCP regions (us-central1, europe-west1) and legacy AWS regions (eu-west-1, us-west-2) for production. Deployments are triggered through Jenkins using the `ruby-pipeline-dsl` shared library and deploy-bot targets defined in `.deploy_bot.yml`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (multi-stage) | `.ci/Dockerfile`; base image `docker.groupondev.com/ruby:2.3`; app image `docker-conveyor.groupondev.com/bookingengine/online_booking_api` |
| Orchestration | Kubernetes (Conveyor Cloud) | Manifest values in `.meta/deployment/cloud/components/app/`; deploy script `.meta/deployment/cloud/scripts/deploy.sh` |
| Load balancer | Nginx (sidecar) + Hybrid Boundary | Rails port 8080; nginx exposes port 80; Hybrid Boundary domain `online-booking-api` |
| CDN | Not applicable | Internal service, no CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging-us-west-2 | Staging (legacy AWS) | us-west-2 | Kubernetes context `online-booking-api-staging-us-west-2` |
| staging-us-central1 | Staging (GCP) | us-central1 | `online-booking-api.staging.service.us-central1.gcp.groupondev.com` |
| staging-europe-west1 | Staging EMEA (GCP) | europe-west1 | Kubernetes context `online-booking-api-gcp-staging-europe-west1` |
| production-us-central1 | Production (GCP) | us-central1 | `online-booking-api.production.service.us-central1.gcp.groupondev.com` |
| production-europe-west1 | Production EMEA (GCP) | europe-west1 | Kubernetes context `online-booking-api-gcp-production-europe-west1` |
| production-eu-west-1 | Production EMEA (legacy AWS) | eu-west-1 | Kubernetes context `online-booking-api-production-eu-west-1` |

Legacy bare-metal/VM internal URLs (still referenced in `.service.yml`):

| Colo | Environment | Internal URL |
|------|-------------|-------------|
| snc1 | production | `http://booking-engine-api-vip.snc1` |
| snc1 | staging | `http://booking-engine-api-staging-vip.snc1` |
| snc1 | emea_staging | `http://booking-engine-api-emea-staging-vip.snc1` |
| snc1 | uat | `http://booking-engine-api-app1-uat.snc1` |
| sac1 | production | `http://booking-engine-api-vip.sac1` |
| dub1 | production | `http://booking-engine-api-vip.dub1` |

## CI/CD Pipeline

- **Tool**: Jenkins with `ruby-pipeline-dsl@latest-2` shared library
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main` or `test` branch; deploy-bot manual triggers

### Pipeline Stages

1. **Build**: Runs RubyGems bundle install, RuboCop lint, Danger checks, RSpec test suite
2. **Deploy to staging**: Deploys to `staging-us-west-2`, `staging-us-central1`, `staging-europe-west1` automatically on successful build of `main`
3. **Promote to production**: `staging-us-central1` promotes to `production-us-central1`; `staging-europe-west1` promotes to `production-eu-west-1`
4. **Notify**: Slack notifications on start, completion, and override events to channel `CF9U0DPC`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (production) | HPA (Kubernetes) | Min 2 / Max 20 replicas; `hpaTargetUtilization: 100` |
| Horizontal (staging) | HPA (Kubernetes) | Min 1 / Max 1 replica |
| Concurrency | Puma threads | `RAILS_MAX_THREADS: 10` per pod |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 500m | No limit defined (common.yml) |
| Memory | 3000Mi | 5000Mi |
| Disk | Not specified | Not specified |

Log files are rotated inside the container every 15 minutes via a cron job; log directory is `/app/log`. Log files are shipped via Filebeat sidecar (`volumeType: medium`) with source type `online-booking-api-app`. Monitored log files: `steno*.log`, `service-discovery-client.log`.
