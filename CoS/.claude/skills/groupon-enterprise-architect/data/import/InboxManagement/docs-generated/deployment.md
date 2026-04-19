---
service: "inbox_management_platform"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [snc1, dub1, sac1]
---

# Deployment

## Overview

InboxManagement is deployed as Docker containers (base image `openjdk:11`) orchestrated by Kubernetes across three regions: snc1 (US primary), dub1 (EU), and sac1 (US secondary). The service runs as multiple sharded daemon instances — each of the six daemon types (coord-worker, dispatcher, user-sync, queue-monitor, error-listener, subscription-listener) is deployed as a separate Kubernetes workload, allowing independent scaling. The Admin UI (Jetty) runs as a separate deployment. The Campaign Metrics Service runs as a companion deployment.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker | Base: `openjdk:11`; one image per daemon type and admin UI |
| Orchestration | Kubernetes | Separate Deployments per daemon type; namespace per environment |
| Redis | Redis (sharded) | Managed sharded Redis cluster — `continuumInboxManagementRedis` |
| PostgreSQL | PostgreSQL | Managed PostgreSQL instance — `continuumInboxManagementPostgres` |
| Load balancer | Kubernetes Service / internal | Admin UI exposed via internal Kubernetes Service; daemons do not expose external endpoints |
| CDN | none | No CDN — admin UI is internal only |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| snc1 | US production primary | snc1 | Internal cluster endpoint |
| dub1 | EU production | dub1 | Internal cluster endpoint |
| sac1 | US production secondary / DR | sac1 | Internal cluster endpoint |

## CI/CD Pipeline

- **Tool**: CI/CD pipeline managed externally (team-owned)
- **Config**: Pipeline configuration not discoverable from architecture model
- **Trigger**: On push to main branch; manual dispatch for emergency deploys

### Pipeline Stages

1. Build: Maven 3 compiles Java 11 source and runs unit tests
2. Package: Docker image built and tagged with commit SHA
3. Push: Image pushed to internal container registry
4. Deploy: Kubernetes manifests applied per target environment (snc1 first, then dub1/sac1)
5. Verify: Healthcheck at `/grpn/healthcheck` confirmed on all daemon pods before traffic cutover

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual / HPA per daemon type | Separate replica counts per daemon; sharded instances for coord-worker and dispatcher |
| Memory | Per-container limits | Set per daemon type based on workload profile |
| CPU | Per-container limits | Set per daemon type based on workload profile |

> Specific replica counts, CPU, and memory request/limit values are managed in Kubernetes manifests external to this architecture repo. Contact the Push - Inbox Management team (dgupta) for current sizing.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > Not discoverable from architecture model | > Not discoverable from architecture model |
| Memory | > Not discoverable from architecture model | > Not discoverable from architecture model |
| Disk | Stateless daemons — no persistent disk | none |

> Deployment configuration for exact resource sizing is managed externally by the Push - Inbox Management team.
