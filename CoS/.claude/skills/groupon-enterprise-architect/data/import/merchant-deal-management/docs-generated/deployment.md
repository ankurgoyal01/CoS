---
service: "merchant-deal-management"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "Not specified"
environments: [development, staging, production]
---

# Deployment

## Overview

The Merchant Deal Management service consists of two deployed process types: the HTTP API (`continuumDealManagementApi`) and the asynchronous worker pool (`continuumDealManagementApiWorker`). Both are Ruby/Rails processes within the Continuum platform. Specific containerization, orchestration technology, and CI/CD pipeline details are not resolvable from the available repository inventory (no Dockerfile, Kubernetes manifests, Helm charts, or CI configuration files were found in the indexed source).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Not specified | No Dockerfile found in repository inventory |
| Orchestration | Not specified | No Kubernetes or ECS manifests found in repository inventory |
| Load balancer | Not specified | Managed by Continuum platform infrastructure |
| CDN | Not specified | No evidence found in repository inventory |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and integration testing | Not specified | Not specified |
| Staging | Pre-production validation | Not specified | Not specified |
| Production | Live traffic serving deal write operations | Not specified | Not specified |

## CI/CD Pipeline

- **Tool**: Not resolvable from available inventory
- **Config**: Not resolvable from available inventory
- **Trigger**: Not resolvable from available inventory

### Pipeline Stages

> Deployment configuration managed externally. No CI/CD pipeline configuration was found in the available repository inventory.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (API) | Not specified | Not resolvable from available inventory |
| Horizontal (Worker) | Not specified; Resque concurrency controlled by worker count | Not resolvable from available inventory |
| Memory | Not specified | Not resolvable from available inventory |
| CPU | Not specified | Not resolvable from available inventory |

## Resource Requirements

> Deployment configuration managed externally. Resource requests and limits are not resolvable from the available inventory.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not specified | Not specified |
| Memory | Not specified | Not specified |
| Disk | Not specified | Not specified |
