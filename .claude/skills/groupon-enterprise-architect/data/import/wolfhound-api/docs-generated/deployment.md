---
service: "wolfhound-api"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Wolfhound API is a JTier-managed Java Dropwizard service deployed as a containerized workload within the Continuum platform. Deployment configuration is managed externally to this architecture repository. The service owns its PostgreSQL database (`continuumWolfhoundPostgres`) which is provisioned alongside it.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile in wolfhound-api source repository |
| Orchestration | Kubernetes (via JTier) | Helm charts / JTier deployment manifests in wolfhound-api source repository |
| Load balancer | > No evidence found | Managed by JTier platform conventions |
| CDN | > No evidence found | Not applicable for internal API |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local developer testing | local | > No evidence found |
| staging | Pre-production integration testing | > No evidence found | > No evidence found |
| production | Live traffic | > No evidence found | > No evidence found |

## CI/CD Pipeline

- **Tool**: > No evidence found in architecture inventory
- **Config**: Managed in wolfhound-api source repository
- **Trigger**: > No evidence found in architecture inventory

### Pipeline Stages

> Deployment configuration managed externally. Consult the wolfhound-api source repository and MEI team (nmallesh) for pipeline stage definitions.

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
| Disk | > No evidence found | > No evidence found |

> Deployment configuration managed externally. Infrastructure details are maintained in the wolfhound-api source repository by the MEI team.
