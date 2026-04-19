---
service: "selfsetup-hbw"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [production, staging]
---

# Deployment

## Overview

selfsetup-hbw is containerised using the `php:5.6-apache` base image and deployed to AWS EKS (Kubernetes). Deployments are managed by DeployBot 2. Two environments are active: production (`dub1`, Dublin) and staging (`snc1`). The Capistrano 3.17.0 toolchain provides the deployment automation pipeline.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Base image: `php:5.6-apache`; application code and Composer dependencies bundled at build time |
| Orchestration | AWS EKS (Kubernetes) | Pod deployment managed by DeployBot 2 |
| Load balancer | > No evidence found | Traffic routing details managed externally |
| CDN | > No evidence found | Not evidenced in inventory |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| production | Live merchant-facing environment | dub1 (Dublin, AWS EU-West-1) | > Not evidenced in inventory |
| staging | Pre-production validation | snc1 (AWS staging cluster) | > Not evidenced in inventory |

## CI/CD Pipeline

- **Tool**: DeployBot 2 + Capistrano 3.17.0
- **Config**: `Capfile` / `config/deploy.rb` (Capistrano convention)
- **Trigger**: Manual deploy via DeployBot 2 UI / CLI

### Pipeline Stages

1. **Build**: Composer installs dependencies (`composer install --no-dev --optimize-autoloader`), Docker image is built with `php:5.6-apache` base
2. **Test**: > No evidence found of automated test stage in the inventory
3. **Push**: Docker image pushed to container registry
4. **Deploy**: DeployBot 2 triggers Capistrano deploy task — rolls out new image to EKS pods in target environment
5. **Verify**: EKS liveness probe hits `/heartbeat.txt` to confirm pod health

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | > Not evidenced — managed by EKS HPA or manual scaling via DeployBot | > Not evidenced in inventory |
| Memory | > Not evidenced in inventory | > Not evidenced in inventory |
| CPU | > Not evidenced in inventory | > Not evidenced in inventory |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > Not evidenced in inventory | > Not evidenced in inventory |
| Memory | > Not evidenced in inventory | > Not eviderated in inventory |
| Disk | > Not applicable (stateless container; data in MySQL) | — |

> Deployment configuration (resource limits, replica counts, ingress rules) is managed externally in the EKS/DeployBot configuration — not committed to this repository.
