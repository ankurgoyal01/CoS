---
service: "service-portal-mcp"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

service-portal-mcp is a stateless Python ASGI application deployable as a container. It supports two transport modes: HTTP (for server deployments) and STDIO (for local agent usage). Deployment configuration is managed externally to this repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Containerized Python 3.13.7 application |
| Orchestration | Kubernetes | Manifest paths managed externally |
| Load balancer | To be confirmed | Routes HTTP traffic to MCP server pods |
| CDN | None | Internal tool; no CDN required |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production validation against staging Service Portal API | To be confirmed | Configured via `SERVICE_PORTAL_API_URL` |
| Production | Live MCP tool service for AI agents | To be confirmed | Configured via `SERVICE_PORTAL_API_URL` |

## CI/CD Pipeline

- **Tool**: To be confirmed — deployment configuration managed externally
- **Config**: Not present in this repository
- **Trigger**: To be confirmed

### Pipeline Stages

1. Test: Run pytest suite against the codebase
2. Build: Package Python application into Docker image
3. Deploy: Push image and apply to target environment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Stateless design supports horizontal scaling | To be confirmed per deployment |
| Memory | To be confirmed | Managed externally |
| CPU | To be confirmed | Managed externally |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | To be confirmed | To be confirmed |
| Memory | To be confirmed | To be confirmed |
| Disk | None (stateless) | None |

> Deployment configuration managed externally. Contact the Platform Engineering team for current resource limits and scaling configuration.
