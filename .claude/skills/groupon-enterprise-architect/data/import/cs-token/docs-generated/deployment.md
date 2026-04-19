---
service: "cs-token"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

CS Token Service is containerized using a two-stage Docker build (Ruby 2.6.3 base image) and deployed to Kubernetes via Conveyor Cloud (Groupon's internal PaaS). It runs as a multi-replica Unicorn Rails process fronted by Nginx. Separate deployments are maintained for NA (GCP us-central1) and EMEA (AWS eu-west-1 / GCP europe-west1) regions. Namespace naming convention includes a `-sox` suffix indicating SOX compliance scope.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (2-stage build) | `.ci/Dockerfile`; base image `docker.groupondev.com/ruby:2.6.3` |
| Orchestration | Kubernetes (Conveyor Cloud) | `.meta/deployment/cloud/components/app/` YAML configs |
| Web server | Unicorn (Rails) + Nginx sidecar | Unicorn on port 8000 (railsPort), Nginx on port 8080 (httpPort) |
| HTTPS Ingress | Conveyor Cloud HTTPS ingress | Port 9443, graceful termination enabled |
| Load balancer | Conveyor Cloud VIP (internal) | VIP per region (see Environments table) |
| Log shipping | Filebeat → Kafka → ELK | `stenoSourceType: "cs-token-service_app"`; per-region Kafka endpoints |
| Metrics | Telegraf → Wavefront | `telegrafUrl` per region; dashboards on Wavefront |

## Environments

| Environment | Purpose | Region / Cloud | VIP / URL |
|-------------|---------|----------------|-----------|
| dev-us-west-1 | Development (AWS) | us-west-1 / AWS | — |
| dev-us-west-2 | Development (AWS) | us-west-2 / AWS | — |
| dev-eu-west-1 | Development (AWS / EMEA) | eu-west-1 / AWS | — |
| staging-us-central1 | Staging NA (GCP) | us-central1 / GCP | `cs-token-service.us-central1.conveyor.stable.gcp.groupondev.com` |
| staging-us-west-1 | Staging NA (AWS) | us-west-1 / AWS | — |
| staging-us-west-2 | Staging NA (AWS) | us-west-2 / AWS | — |
| staging-europe-west1 | Staging EMEA (GCP) | europe-west1 / GCP | — |
| staging-eu-west-1 | Staging EMEA (AWS) | eu-west-1 / AWS | — |
| production-us-central1 | Production NA (GCP) | us-central1 / GCP | `cs-token-service.prod.us-central1.aws.groupondev.com`; healthcheck: `https://cs-token-service.production.service.us-central1.gcp.groupondev.com/heartbeat.txt` |
| production-eu-west-1 | Production EMEA (AWS) | eu-west-1 / AWS | `cs-token-service.prod.eu-west-1.aws.groupondev.com`; healthcheck: `https://cs-token-service.production.service.eu-west-1.aws.groupondev.com/heartbeat.txt` |
| production-europe-west1 | Production EMEA (GCP) | europe-west1 / GCP | — |
| production-us-west-1 | Production NA (AWS) | us-west-1 / AWS | — |

All production and staging Kubernetes namespaces use the `-sox` suffix (e.g., `cs-token-service-production-sox`, `cs-token-service-staging-sox`).

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Library**: `ruby-pipeline-dsl@latest-2`
- **Trigger**: On push to `main`, `release.*` branches; manual dispatch
- **Slack**: `#cs-internal-alerts`

### Pipeline Stages

1. **Build**: Bundle install, Docker image build and push to `docker-conveyor.groupondev.com/sox-inscope/cs-token`
2. **Test**: RSpec test suite; SimpleCov coverage; RuboCop lint
3. **Deploy to Staging**: Auto-deploy to `staging-us-central1` and `staging-europe-west1` on releasable branches
4. **Deploy to Production**: Manual promotion via Conveyor Cloud deploy bot (`.deploy_bot.yml`)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA / manual min-max | Staging: min 1, max 2; Production: min 2, max 3 |
| HPA target | CPU utilization | `hpaTargetUtilization: 100` (common config) |
| Memory | Limit-based | Request: 500 Mi; Limit: 500 Mi (staging) / 1000 Mi (production) |
| CPU | Request-based | Request: 300m (common config) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 300m | Not specified (common config) |
| Memory | 500 Mi | 500 Mi (staging) / 1000 Mi (production) |
| Disk | Standard ephemeral | `/var/groupon/logs` symlinked to log dir |

## Health Check

- **Path**: `/heartbeat.txt`
- **Port**: 8080 (Nginx)
- **Behavior**: Returns `200` with heartbeat text content; returns `503` if `heartbeat.txt` file is missing
