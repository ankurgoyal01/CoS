---
service: "bookingtool"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

The Booking Tool runs as a containerized PHP application (Apache + PHP-FPM) deployed to Kubernetes in AWS `eu-west-1`. Deployment is managed by Capistrano 3.6.1 using Ruby 2.2.2. The service is multi-locale, serving UK, US, AU, FR, DE, ES, NL, IT, PL, BE, IE, and AE markets from the same deployment.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | PHP 5.6 + Apache + PHP-FPM base image |
| Orchestration | Kubernetes | Manifest paths not evidenced in inventory |
| Web server | Apache | Fronts PHP-FPM process pool |
| PHP runtime | PHP-FPM | Handles request processing |
| Load balancer | Kubernetes Service / ALB | AWS Application Load Balancer in eu-west-1 |
| CDN | > No evidence found | — |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and feature testing | — | localhost |
| Staging | Pre-production validation and integration testing | eu-west-1 | Internal staging URL |
| Production | Live merchant and customer traffic | eu-west-1 | Production EMEA URL |

## CI/CD Pipeline

- **Tool**: Capistrano 3.6.1
- **Config**: `Capfile`, `config/deploy.rb`, `config/deploy/<env>.rb`
- **Trigger**: Manual deployment via Capistrano CLI; no evidence of automated CI/CD pipeline in inventory

### Pipeline Stages

1. Code preparation: Checkout source, install Composer dependencies
2. Asset compilation: Run any pre-deployment build steps
3. Deploy: Capistrano rsync/SSH to target servers or Kubernetes apply
4. Symlink: Switch current release symlink to new deployment
5. Restart: Reload PHP-FPM and Apache workers

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA or manual replica count | Min/max replica count not evidenced in inventory |
| Memory | Kubernetes resource limits | Limits not evidenced in inventory |
| CPU | Kubernetes resource limits | Limits not evidenced in inventory |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > Deployment configuration managed externally | > Deployment configuration managed externally |
| Memory | > Deployment configuration managed externally | > Deployment configuration managed externally |
| Disk | > Deployment configuration managed externally | > Deployment configuration managed externally |

> Kubernetes resource requests and limits are managed externally in cluster configuration not included in this repository inventory.
