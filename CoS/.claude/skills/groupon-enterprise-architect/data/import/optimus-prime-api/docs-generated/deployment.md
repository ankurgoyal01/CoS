---
service: "optimus-prime-api"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "continuum-platform"
environments: [development, staging, production]
---

# Deployment

## Overview

Optimus Prime API is a Java 17 JTier/Dropwizard service deployed as part of the Continuum platform. It is built into an executable JAR with embedded Jetty and deployed via the Continuum platform toolchain. Flyway database migrations run automatically at startup against `continuumOptimusPrimeApiDb`. Quartz Scheduler runs in-process and does not require external coordination. Cloud storage (GCS, S3) and NiFi clusters are provisioned and managed externally.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Java JAR (Dropwizard / JTier embedded Jetty) | Maven-built artifact; `jtier-service-pom v5.14.0` parent |
| Database | PostgreSQL | `continuumOptimusPrimeApiDb` — provisioned externally |
| Cloud storage | Google Cloud Storage, Amazon S3 | `continuumOptimusPrimeGcsBucket`, `continuumOptimusPrimeS3Storage` |
| Orchestration | Continuum platform (JTier) | Deployment configuration managed externally |
| Load balancer | No evidence found in codebase | |
| CDN | Not applicable | |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and integration testing | — | — |
| Staging | Pre-production validation | — | — |
| Production | Live ETL job management and execution | — | — |

> Environment-specific URLs and regions are managed externally and are not defined in the architecture model.

## CI/CD Pipeline

- **Tool**: No evidence found in codebase
- **Config**: No evidence found in codebase
- **Trigger**: No evidence found in codebase

### Pipeline Stages

> Deployment configuration managed externally. Pipeline details are not defined in the architecture module of this repository.

## Scaling

> No evidence found in codebase. Scaling configuration is managed externally by the Continuum platform deployment toolchain. The Quartz Scheduler and JDBI connection pool sizes are configurable in the application YAML.

## Resource Requirements

> No evidence found in codebase. Resource requests and limits are managed externally. The service holds NiFi client connections, JDBI connection pools, and SSHJ SFTP sessions in memory; memory sizing should account for concurrent run concurrency.
