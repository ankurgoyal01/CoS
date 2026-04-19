---
service: "partner-service"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "ecs"
environments: [development, staging, production]
---

# Deployment

## Overview

Partner Service is a JTier-managed Dropwizard Java service deployed as a containerized workload on Groupon's internal JTier platform. Deployment follows the standard JTier/Continuum deployment model: Maven builds a fat JAR, which is packaged into a Docker image and deployed to the JTier container orchestration environment. Flyway migrations run on startup against `continuumPartnerServicePostgres`.

> Deployment configuration is managed externally by the JTier platform team. Details below reflect the standard JTier/Continuum pattern; service-specific overrides are not enumerated in this repository's inventory.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard JTier base image with Java 17; fat JAR entry point |
| Orchestration | JTier / ECS | Managed by JTier platform; no Kubernetes manifests identified |
| Load balancer | Internal JTier LB | HTTP traffic routed via JTier service mesh |
| CDN | None | Internal service; no CDN layer |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local and CI development testing | — | Internal dev cluster |
| Staging | Pre-production integration and QA | — | Internal staging cluster |
| Production | Live partner management operations | — | Internal production cluster |

## CI/CD Pipeline

- **Tool**: Jenkins (standard JTier/Continuum CI pattern)
- **Config**: Managed by JTier platform team outside this repository
- **Trigger**: On merge to main branch; manual deploy available

### Pipeline Stages

1. Build: `mvn clean package` produces fat JAR with all dependencies
2. Test: Unit and integration tests run against an in-process database
3. Package: Docker image built with Java 17 fat JAR
4. Migrate: Flyway migrations applied to target environment PostgreSQL on deploy
5. Deploy: JTier platform deploys container image to target environment
6. Verify: Health check endpoint polled to confirm successful startup

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | JTier platform managed | Minimum/maximum instance counts managed by platform team |
| Memory | JVM heap + container limit | Configured per environment by JTier platform team |
| CPU | Container limit | Configured per environment by JTier platform team |

## Resource Requirements

> Deployment configuration managed externally. Specific CPU, memory, and disk resource requests/limits are defined in JTier platform configuration outside this repository.
