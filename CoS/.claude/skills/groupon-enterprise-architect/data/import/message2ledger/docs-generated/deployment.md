---
service: "message2ledger"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

message2ledger is a JTier/Dropwizard Java service deployed as a containerized application on Groupon's Continuum platform infrastructure. It follows the standard JTier deployment model with environment-specific configuration supplied at runtime. Deployment configuration is managed externally to this architecture repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard JTier Java service container image |
| Orchestration | Kubernetes / JTier platform | Deployed via JTier platform orchestration tooling |
| Load balancer | Internal (JTier) | Internal service traffic only; no public load balancer required |
| CDN | none | No CDN — internal service with no public traffic |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| dev | Local development and integration testing | NA | Internal only |
| staging (itier) | Pre-production integration with live staging dependencies | NA / EMEA | Internal only |
| production | Live order and inventory ledger event processing | NA + EMEA | Internal only |

## CI/CD Pipeline

- **Tool**: Deployment configuration managed externally to this repository
- **Config**: To be confirmed in the service repository
- **Trigger**: To be confirmed in the service repository

### Pipeline Stages

> Deployment configuration managed externally. Pipeline stages to be confirmed in the service repository.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | JTier platform auto-scaling | Min/max instance counts managed by JTier platform configuration |
| Memory | JVM heap tuning | JVM flags configured per environment |
| CPU | Platform-managed | Limits set by JTier deployment manifests |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | To be confirmed | To be confirmed |
| Memory | To be confirmed | To be confirmed |
| Disk | Minimal (stateless; MySQL is external) | To be confirmed |

> Deployment configuration managed externally. Resource requests and limits are defined in JTier deployment manifests in the service repository.
