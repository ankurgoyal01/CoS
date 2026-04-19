---
service: "bynder-integration-service"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "No evidence found in codebase."
environments: [development, staging, production]
---

# Deployment

## Overview

The bynder-integration-service is a Continuum platform JTier/Dropwizard service deployed as a containerized application running on OpenJDK 11. It is built with Maven and follows the standard Continuum JTier deployment model. Specific orchestration details are not discoverable from the service repository inventory.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | > No Dockerfile path evidence found in codebase. |
| Orchestration | > No evidence found in codebase. | Deployment configuration managed externally. |
| Load balancer | > No evidence found in codebase. | Deployment configuration managed externally. |
| CDN | None | Internal API service; no CDN required. |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development | local | http://localhost:8080 |
| staging | Pre-production integration testing | > No evidence found in codebase. | > No evidence found in codebase. |
| production | Live editorial image sync and API traffic | > No evidence found in codebase. | > No evidence found in codebase. |

## CI/CD Pipeline

- **Tool**: > No evidence found in codebase.
- **Config**: > No pipeline config path discoverable from inventory.
- **Trigger**: > No evidence found in codebase.

### Pipeline Stages

1. **Test**: Run Maven test suite (`mvn test`) including WireMock-based integration tests
2. **Build**: Compile and package fat JAR (`mvn package`)
3. **Docker Build**: Build Docker image with embedded fat JAR
4. **Deploy**: Push image to registry and deploy to target environment

> Detailed pipeline stages are not discoverable from the service inventory. Deployment configuration managed externally.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | > No evidence found in codebase. | > No evidence found in codebase. |
| Memory | > No evidence found in codebase. | JVM heap sizing via JVM_OPTS |
| CPU | > No evidence found in codebase. | > No evidence found in codebase. |

Dropwizard provides a built-in Jetty server with configurable thread pools for HTTP request handling. Quartz scheduler runs in-process for scheduled jobs.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found in codebase. | > No evidence found in codebase. |
| Memory | > No evidence found in codebase. | Java 11 JVM heap; exact limits not discoverable |
| Disk | > No evidence found in codebase. | > No evidence found in codebase. |

> Deployment configuration managed externally.
