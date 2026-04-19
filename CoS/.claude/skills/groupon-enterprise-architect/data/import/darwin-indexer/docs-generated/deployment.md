---
service: "darwin-indexer"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

darwin-indexer is a Java/Dropwizard background service deployed as a containerized workload within Continuum's infrastructure. It does not serve external traffic, so it requires no load balancer or CDN. Deployment configuration (Kubernetes manifests, Helm charts, or equivalent) is managed externally to this architecture repository.

> Deployment configuration managed externally. The details below reflect what is discoverable from the architecture model and Dropwizard conventions; the service owner should confirm specifics.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile in darwin-indexer application repository |
| Orchestration | Kubernetes (assumed, standard Groupon Continuum pattern) | Manifests managed in service or platform repo |
| Load balancer | None | No public-facing HTTP — admin port 9001 for internal ops only |
| CDN | None | Not applicable |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local and feature branch testing | Local / developer workstation | localhost:9001 (admin) |
| Staging | Integration and pre-production validation | > No evidence found | > No evidence found |
| Production | Live deal and hotel offer indexing | > No evidence found | Admin endpoint internal only |

## CI/CD Pipeline

- **Tool**: > No evidence found — assumed GitHub Actions or Jenkins based on Groupon standard patterns
- **Config**: Pipeline configuration in the darwin-indexer application repository
- **Trigger**: On merge to main branch; scheduled daily builds may also trigger index validation jobs

### Pipeline Stages

1. Build: Maven compile, test, and package (`mvn package`)
2. Unit test: Maven Surefire plugin executes unit tests
3. Integration test: Tests against in-process Elasticsearch and PostgreSQL (if configured)
4. Docker image build: Packages JAR into Docker image
5. Push to registry: Publishes Docker image to internal container registry
6. Deploy to staging: Kubernetes rolling update of staging deployment
7. Deploy to production: Kubernetes rolling update of production deployment (gated on staging validation)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual / single replica (indexing service — concurrent runs not expected) | > No evidence found |
| Memory | JVM heap tuned for bulk Elasticsearch operations | > No evidence found |
| CPU | > No evidence found | > No evidence found |

> Horizontal scaling of indexing services requires careful coordination to avoid duplicate index writes. Single-replica deployment is the standard pattern for scheduled indexers.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found | > No evidence found |
| Memory | > No evidence found — JVM heap sizing should account for Elasticsearch bulk buffer and RxJava pipeline buffering | > No evidence found |
| Disk | Minimal (no local data; uses external Elasticsearch and PostgreSQL) | > No evidence found |
