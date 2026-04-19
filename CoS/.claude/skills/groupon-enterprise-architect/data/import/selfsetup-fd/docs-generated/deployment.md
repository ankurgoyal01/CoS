---
service: "selfsetup-fd"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

selfsetup-fd is packaged as a Docker image based on `php:5.6-apache` and deployed to Kubernetes. Production runs in Dublin (`dub1`); staging runs in `snc1`. Deployment automation uses Capistrano 3.6.1 (Ruby 2.3.3). Apache listens on port `8080` inside the container.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Base image: `php:5.6-apache`; Apache port: `8080` |
| Orchestration | Kubernetes | Deployed to `dub1` (production) and `snc1` (staging) |
| Load balancer | > No evidence found | Likely handled by Kubernetes ingress; details not in inventory |
| CDN | > No evidence found | Not applicable for an employee-internal tool |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pre-production validation of setup flows and integrations | snc1 | Not evidenced in inventory |
| production | Live employee-facing F&D BT self-setup tool | dub1 (Dublin, EMEA) | Not evidenced in inventory |

## CI/CD Pipeline

- **Tool**: Capistrano 3.6.1 (Ruby 2.3.3)
- **Config**: `Gemfile` / Capistrano configuration files
- **Trigger**: Manual deployment via Capistrano tasks; CI tool not evidenced in inventory

### Pipeline Stages

1. Dependency install: Composer installs PHP dependencies; Bundler installs Ruby/Capistrano dependencies
2. Build: Docker image built from `php:5.6-apache` base with application code and Composer vendor directory
3. Deploy: Capistrano pushes image and applies Kubernetes manifests to target environment (`dub1` or `snc1`)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes (manual or HPA) | No evidence found of specific min/max/target values |
| Memory | Kubernetes resource limits | No evidence found of specific values |
| CPU | Kubernetes resource limits | No evidence found of specific values |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found | > No evidence found |
| Memory | > No evidence found | > No evidence found |
| Disk | > Not applicable | > Not applicable |

> Deployment configuration (Kubernetes manifests, resource limits, HPA settings) is managed externally and not present in the architecture inventory.
