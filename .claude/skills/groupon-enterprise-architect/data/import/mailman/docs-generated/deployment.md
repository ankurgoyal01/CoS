---
service: "mailman"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Mailman is a Spring Boot 1.2.2 Java service deployed as a containerized application within the Continuum platform. It requires a connected PostgreSQL 13.1 instance (`mailmanPostgres`) and MBus broker at startup. Deployment configuration is managed externally to this architecture repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Java 11 / Spring Boot fat JAR |
| Orchestration | No evidence found | Deployment configuration managed externally |
| Load balancer | No evidence found | Deployment configuration managed externally |
| CDN | None | Backend service; not CDN-fronted |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and integration testing | No evidence found | No evidence found |
| Staging | Pre-production validation | No evidence found | No evidence found |
| Production | Live transactional email processing | No evidence found | No evidence found |

## CI/CD Pipeline

- **Tool**: No evidence found — pipeline configuration managed externally
- **Config**: No evidence found
- **Trigger**: No evidence found

### Pipeline Stages

> Deployment configuration managed externally. Contact Rocketman-India-Team (balsingh) for pipeline details.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | No evidence found | Deployment configuration managed externally |
| Memory | No evidence found | Deployment configuration managed externally |
| CPU | No evidence found | Deployment configuration managed externally |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | No evidence found | No evidence found |
| Memory | No evidence found | No evidence found |
| Disk | No evidence found | No evidence found |

> Deployment configuration managed externally. Infrastructure and sizing details are maintained by the Rocketman-India-Team and the Continuum platform team.
