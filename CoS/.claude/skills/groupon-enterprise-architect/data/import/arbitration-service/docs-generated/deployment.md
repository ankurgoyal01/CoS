---
service: "arbitration-service"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production-snc1, production-sac1, production-dub1, production-cloud]
---

# Deployment

## Overview

The Arbitration Service runs as a Docker container orchestrated by Kubernetes across multiple on-premises and cloud regions. Deployments are managed through Conveyor/Krane, Groupon's internal deployment tooling. The service is horizontally auto-scaled and exposes `/health` for Kubernetes readiness and liveness probes.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Containerized Go binary; Dockerfile path not discoverable from inventory |
| Orchestration | Kubernetes | Multi-region deployment via Conveyor/Krane |
| Load balancer | > No evidence found in codebase | Assumed cluster-internal service routing |
| CDN | None | Internal service, not CDN-fronted |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and integration testing | local | > Not applicable |
| staging | Pre-production validation | > Not specified in inventory | > Not specified |
| production | Live traffic — primary US west | snc1 | > Not specified |
| production | Live traffic — secondary US west | sac1 | > Not specified |
| production | Live traffic — EMEA | dub1 | > Not specified |
| production | Live traffic — cloud | cloud | > Not specified |

## CI/CD Pipeline

- **Tool**: Conveyor / Krane (Groupon internal deployment platform)
- **Config**: > Deployment manifest paths not discoverable from inventory
- **Trigger**: > Not specified in inventory; assumed on-merge to main branch

### Pipeline Stages

1. Build: Compile Go binary and build Docker image
2. Test: Execute unit and integration test suites
3. Validate: Run linting and static analysis
4. Deploy: Push image and deploy via Conveyor/Krane to target region(s)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min: 3 replicas, Max: 12 replicas, Target: 70% CPU utilization |
| Memory | > No evidence found in codebase | Resource limits managed via Kubernetes manifests |
| CPU | > No evidence found in codebase | Resource requests managed via Kubernetes manifests |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found in codebase | > No evidence found in codebase |
| Memory | > No evidence found in codebase | > No evidence found in codebase |
| Disk | > Not applicable | > Not applicable |

> Specific resource request/limit values are managed in Kubernetes manifests controlled by Conveyor/Krane; detailed values not discoverable from the service inventory alone.
