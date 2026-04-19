---
service: "dynamic_pricing"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

The Pricing Service is deployed as a containerized application on Kubernetes. Inbound traffic is received through the `apiProxy` and routed via the `continuumDynamicPricingNginx` NGINX proxy layer, which distributes requests across read and write pricing pods. The NGINX container exposes a `/heartbeat.txt` endpoint for Kubernetes liveness and readiness probes.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Java application packaged as a Docker image |
| Orchestration | Kubernetes | Pod deployment for Pricing Service and NGINX proxy |
| Load balancer | NGINX (`continuumDynamicPricingNginx`) | Routes read/write traffic to upstream pricing pods; configured per routing rules |
| API Proxy | `apiProxy` | Upstream hybrid boundary proxy routing external traffic to the NGINX layer |
| Logging | Filebeat/HTTP | NGINX log emitter ships access/error logs to `loggingStack` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local and CI validation | No evidence found | No evidence found |
| Staging | Integration and pre-production testing | No evidence found | No evidence found |
| Production | Live customer traffic | No evidence found | No evidence found |

> Deployment configuration managed externally. Specific environment URLs and regions are not discoverable from the architecture inventory.

## CI/CD Pipeline

- **Tool**: No evidence found — pipeline configuration is external to this architecture inventory
- **Config**: No evidence found
- **Trigger**: No evidence found

### Pipeline Stages

> No evidence found for pipeline stage definitions in the available architecture inventory. Operational procedures to be defined by service owner.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes pod scaling for Pricing Service | Separate read and write pod groups routed by NGINX |
| Memory | No evidence found | No evidence found |
| CPU | No evidence found | No evidence found |

> The NGINX routing layer (`continuumDynamicPricingNginx`) supports separate read and write upstream pod pools, enabling independent scaling of read-heavy and write-heavy workloads.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | No evidence found | No evidence found |
| Memory | No evidence found | No evidence found |
| Disk | No evidence found | No evidence found |

> Deployment configuration managed externally. Resource requests and limits are defined in Kubernetes manifests not included in this architecture inventory.
