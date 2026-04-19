---
service: "accounting-service"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Accounting Service is containerized with Docker and deployed to Kubernetes via the Groupon cloud-elevator platform. CI/CD is managed by Jenkins using the `ruby-pipeline-dsl` pipeline definition. Production deployments are SOX-inscope and require GPROD approval before promotion. The service runs two container types in the same deployment: the Rails web application and Resque worker processes.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile at repository root; Rails app and Resque workers share the same image |
| Orchestration | Kubernetes (cloud-elevator) | Kubernetes manifests managed by cloud-elevator platform tooling |
| Load balancer | Groupon platform default | Configured by cloud-elevator; routes traffic to Rails web container |
| CDN | None | Internal service; not exposed via CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development | Local | localhost |
| staging | Pre-production validation | Groupon internal | Internal staging URL managed by cloud-elevator |
| production | SOX-inscope production | Groupon production | Internal production URL managed by cloud-elevator |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `ruby-pipeline-dsl` (pipeline definition DSL managed at the Groupon platform level)
- **Trigger**: On push to main branch; manual dispatch for hotfixes; GPROD approval gate required for production promotion

### Pipeline Stages

1. **Install dependencies**: `bundle install` with Bundler 1.17.3 resolving `Gemfile.lock`
2. **Test**: Run Rails test suite; code coverage tracked via Coverband
3. **Build**: Docker image build and push to internal container registry
4. **Deploy to staging**: cloud-elevator promotes image to staging Kubernetes namespace
5. **GPROD approval gate**: SOX-required manual approval step for production changes
6. **Deploy to production**: cloud-elevator promotes approved image to production Kubernetes namespace

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA or manual replica configuration via cloud-elevator | Configured per environment in cloud-elevator manifests |
| Memory | Kubernetes resource limits | Configured in cloud-elevator deployment manifests |
| CPU | Kubernetes resource limits | Configured in cloud-elevator deployment manifests |

> Specific replica counts and resource limits are managed by the cloud-elevator platform and are not discoverable from this repository inventory.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Managed by cloud-elevator | Managed by cloud-elevator |
| Memory | Managed by cloud-elevator | Managed by cloud-elevator |
| Disk | Stateless container; no persistent disk | Not applicable |

> Deployment configuration managed by cloud-elevator platform. Contact the Finance Engineering team (fed@groupon.com) or the cloud-elevator platform team for specific resource configurations.
