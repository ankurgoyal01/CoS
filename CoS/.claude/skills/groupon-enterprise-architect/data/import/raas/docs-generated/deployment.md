---
service: "raas"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

RaaS is a multi-component platform. The K8s Config Updater (`continuumRaasConfigUpdaterService`) runs as a Kubernetes deployment and manages in-cluster telegraf config maps. The Info Service (`continuumRaasInfoService`) runs as a Rails/Puma application behind an internal load balancer. Background daemons (API Caching, Monitoring, Checks Runner) and admin tooling (Terraform Afterhook, Ansible Admin) are deployed as scheduled jobs or operator-run tooling. Deployment configuration details beyond Kubernetes are managed externally.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Containers for Info Service and K8s Config Updater |
| Orchestration | Kubernetes | Config Updater uses in-cluster API; telegraf deployments managed via config maps |
| Load balancer | Internal | Info Service exposed internally; specific LB technology not in architecture model |
| CDN | none | Internal operations platform only |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pre-production validation | > No evidence found | > No evidence found |
| production | Live Redis operations platform | > No evidence found | > No evidence found |

## CI/CD Pipeline

- **Tool**: > No evidence found in architecture model
- **Config**: > Deployment pipeline configuration managed externally
- **Trigger**: > No evidence found

### Pipeline Stages

> Deployment configuration managed externally. Contact raas-team@groupon.com for CI/CD pipeline details.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | > No evidence found | > No evidence found |
| Memory | > No evidence found | > No evidence found |
| CPU | > No evidence found | > No evidence found |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found | > No evidence found |
| Memory | > No evidence found | > No evidence found |
| Disk | Filesystem cache storage for `api_cache/` and `raas_info/` directories | > No evidence found |

> Deployment configuration beyond the architecture model is managed externally by the raas-team. Contact raas-team@groupon.com for detailed deployment manifests and resource requirements.
