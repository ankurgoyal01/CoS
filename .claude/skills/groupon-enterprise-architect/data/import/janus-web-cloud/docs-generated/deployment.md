---
service: "janus-web-cloud"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Janus Web Cloud is a JVM-based Dropwizard/JTier service deployed as part of the Continuum platform. It follows standard JTier deployment conventions for Groupon's cloud infrastructure. The service is deployed as a containerised application with a clustered Quartz scheduler requiring all instances to share the same `continuumJanusMetadataMySql` database for distributed job coordination.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard JTier base image; Dockerfile path not available in architecture model |
| Orchestration | Kubernetes (inferred from JTier/Continuum conventions) | Deployment manifests managed externally |
| Load balancer | Internal platform load balancer | Routes traffic to Janus Web Cloud Service instances |
| CDN | none | Internal service; not internet-facing |

> Deployment configuration managed externally. The architecture model does not contain Dockerfile, Kubernetes manifests, or CI/CD pipeline configuration paths. The source repository should be consulted for exact deployment artifacts.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local or dev-tier development and testing | — | — |
| Staging | Pre-production integration and QA | — | — |
| Production | Live traffic serving operator tooling and internal consumers | — | — |

## CI/CD Pipeline

- **Tool**: No evidence found in architecture model — refer to the source repository
- **Config**: No evidence found
- **Trigger**: No evidence found

### Pipeline Stages

> No evidence found. Refer to the source repository CI/CD configuration.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Multiple instances supported via Quartz clustered mode (shared MySQL scheduler tables) | No evidence found of min/max replica counts |
| Memory | No evidence found | — |
| CPU | No evidence found | — |

> Note: Quartz clustering (`quartzSchedulerTables` in `continuumJanusMetadataMySql`) enables horizontal scaling. All instances must point to the same MySQL database and share the same `QUARTZ_CLUSTER_ID`.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | No evidence found | No evidence found |
| Memory | No evidence found | No evidence found |
| Disk | No evidence found | No evidence found |

> Deployment configuration managed externally.
