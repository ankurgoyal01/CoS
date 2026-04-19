---
service: "orders-rails3"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

orders-rails3 is deployed as three distinct process types within the Continuum platform: the Rails API served by Unicorn (`continuumOrdersService`), the Resque background worker pool (`continuumOrdersWorkers`), and the cron/daemon process (`continuumOrdersDaemons`). All three are containerized and deployed to Kubernetes. The service is SOX in-scope, so production deployments follow change management procedures.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile at repository root; separate targets for API, Workers, and Daemons |
| Orchestration | Kubernetes | Deployment manifests manage API, Workers, and Daemons as separate Deployments |
| Load balancer | Nginx / ALB | Sits in front of Unicorn API workers; terminates TLS |
| CDN | Not applicable | Orders API is not a public-facing CDN-cached endpoint |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and unit testing | local | http://localhost:3000 |
| staging | Integration and QA testing against staging tier services | US | Internal staging URL |
| production | Live order processing for all Groupon commerce | US / EU | Internal production URL |

## CI/CD Pipeline

- **Tool**: Jenkins / GitHub Actions (Continuum platform standard)
- **Config**: Deployment configuration managed externally to this architecture repository
- **Trigger**: On merge to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. Build: Runs unit and integration test suite; builds Docker image
2. Validate: Runs schema migrations dry-run against staging database
3. Deploy Staging: Rolls out to staging Kubernetes cluster; smoke tests
4. Deploy Production: Rolling deployment to production; requires change approval (SOX in-scope)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (API) | Horizontal Pod Autoscaler | Min/max configured per production load profile |
| Horizontal (Workers) | Manual / HPA on queue depth | Resque worker count tuned to queue backlog |
| Horizontal (Daemons) | Single instance | Daemons run as singleton to avoid duplicate scheduling |
| Memory | Resource limits per pod | Configured in Kubernetes Deployment manifests |
| CPU | Resource limits per pod | Configured in Kubernetes Deployment manifests |

## Resource Requirements

> Deployment configuration managed externally. Specific CPU and memory requests/limits are defined in Kubernetes Deployment manifests outside this repository.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Per Kubernetes manifest | Per Kubernetes manifest |
| Memory | Per Kubernetes manifest | Per Kubernetes manifest |
| Disk | Ephemeral only | Not applicable |
