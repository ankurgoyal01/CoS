---
service: "email_campaign_management"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

CampaignManagement is deployed as a containerized Node.js service within the Continuum platform. Orchestration and environment-specific configuration follow Continuum platform conventions. Specific Kubernetes manifest paths, Dockerfile locations, and CI/CD pipeline configuration were not discoverable from the architecture inventory; deployment details are managed externally by the Campaign Management / PMP team and the Continuum platform engineering group.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile path not discoverable from architecture inventory |
| Orchestration | Kubernetes | Manifest paths managed externally |
| Load balancer | Internal platform LB | Continuum internal routing |
| CDN | Not applicable | Internal service only; no public CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local and CI development | — | Internal only |
| staging | Pre-production integration testing | — | Internal only |
| production | Live traffic at 70M+ send scale | — | Internal only |

## CI/CD Pipeline

- **Tool**: Deployment configuration managed externally
- **Config**: `> No evidence found — pipeline config path not discoverable from architecture inventory`
- **Trigger**: `> No evidence found`

### Pipeline Stages

> Deployment configuration managed externally. Operational procedures to be defined by service owner.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA or manual | `> No evidence found` |
| Memory | Platform-defined limits | `> No evidence found` |
| CPU | Platform-defined limits | `> No evidence found` |

> The service operates at 70M+ email send scale; horizontal scaling of the Node.js API tier is expected. Specific HPA min/max/target values are managed externally.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | `> No evidence found` | `> No evidence found` |
| Memory | `> No evidence found` | `> No evidence found` |
| Disk | Stateless — no local disk required | — |

> Deployment configuration managed externally. Contact the Campaign Management / PMP team for current resource allocations.
