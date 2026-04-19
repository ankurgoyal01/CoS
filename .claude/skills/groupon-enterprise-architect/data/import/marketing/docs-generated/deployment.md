---
service: "marketing"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["production"]
---

# Deployment

## Overview

The Marketing & Delivery Platform is deployed on **GCP** within the **Conveyor Cloud (Kubernetes)** cluster as part of the Continuum Platform production environment. The deployment model from the architecture DSL shows two container instances: `mailman` and `rocketman`, both mapped to the `continuumMarketingPlatform` container, indicating the platform runs as two distinct Kubernetes deployments sharing the same logical container definition.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (inferred) | Containerized deployment on Kubernetes |
| Orchestration | Kubernetes (Conveyor Cloud on GCP) | `model/deployment/gcp.dsl` |
| Load balancer | > No evidence found in codebase. | |
| CDN | > No evidence found in codebase. | |

## Deployment Instances

| Instance | Container Ref | Description |
|----------|--------------|-------------|
| `mailman` | `continuumMarketingPlatform` | Campaign delivery and messaging instance |
| `rocketman` | `continuumMarketingPlatform` | Campaign delivery and messaging instance |

> Both `mailman` and `rocketman` are deployed as separate container instances of the same logical Marketing & Delivery Platform container, likely handling different campaign delivery channels or workload partitions.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Production | Live campaign management and delivery | GCP (Conveyor Cloud) | > No evidence found in codebase. |

## CI/CD Pipeline

> No evidence found in codebase. CI/CD pipeline configuration is not discoverable from the architecture model.

- **Tool**: > No evidence found in codebase.
- **Config**: > No evidence found in codebase.
- **Trigger**: > No evidence found in codebase.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | > No evidence found in codebase. | |
| Memory | > No evidence found in codebase. | |
| CPU | > No evidence found in codebase. | |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found in codebase. | |
| Memory | > No evidence found in codebase. | |
| Disk | > No evidence found in codebase. | |
