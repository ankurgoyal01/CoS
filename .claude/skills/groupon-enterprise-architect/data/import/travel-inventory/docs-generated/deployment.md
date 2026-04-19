---
service: "travel-inventory"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "GCP"
environments: [development, staging, production]
---

# Deployment

## Overview

Getaways Inventory Service runs as a Java/Tomcat web application deployed on Google Cloud Platform (GCP). The primary service container (`continuumTravelInventoryService`) serves HTTP API traffic, while a companion Python cron container (`continuumTravelInventoryCron`) runs on a schedule to trigger daily inventory report generation. Supporting infrastructure includes a MySQL database, two Redis instances (hotel product cache and inventory product cache), a Memcached instance (Backpack availability cache), and an AWS SFTP Transfer endpoint for report file delivery.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Primary service container | Java 8, Tomcat, GCP | Serves all REST API endpoints via Jersey/Skeletor |
| Cron container | Python 3.8 | Scheduled trigger for daily inventory report generation |
| Database | MySQL | Getaways Inventory DB with read/write role routing |
| Cache (Hotel Product) | Redis | Dedicated Redis instance for hotel product detail caching |
| Cache (Inventory Product) | Redis | Dedicated Redis instance for inventory product snapshot caching |
| Cache (Availability) | Memcached | Dedicated Memcached instance for Backpack availability caching |
| File transfer | AWS SFTP Transfer | Managed SFTP endpoint for daily report CSV export |
| Load balancer | GCP Load Balancer (assumed) | Routes HTTP traffic to Tomcat instances |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Development and local testing | GCP (region varies) | Internal dev URL |
| Staging | Pre-production validation | GCP (region varies) | Internal staging URL |
| Production | Live traffic serving | GCP (region varies) | Internal production URL |

## CI/CD Pipeline

- **Tool**: Deployment configuration managed externally (consult service owner for CI/CD tooling details)
- **Config**: Deployment manifests managed in the service codebase or infrastructure repository
- **Trigger**: On merge to main branch (assumed); consult service owner for exact pipeline configuration

### Pipeline Stages

1. **Build**: Compile Java source, run unit tests, package WAR/JAR artifact
2. **Test**: Run integration tests against staging dependencies
3. **Deploy to Staging**: Deploy artifact to staging environment
4. **Validate Staging**: Run smoke tests against staging endpoints
5. **Deploy to Production**: Promote validated artifact to production environment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Auto-scaling based on CPU/memory and request rate (assumed) | Consult infrastructure configuration |
| Memory | JVM heap sizing for Tomcat | Configured per environment |
| CPU | Multi-instance deployment behind load balancer | Configured per environment |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Consult infrastructure configuration | Consult infrastructure configuration |
| Memory | Consult infrastructure configuration | Consult infrastructure configuration |
| Disk | Minimal (stateless service; temp space for report generation) | Consult infrastructure configuration |

> Deployment configuration details beyond what is modelled in the architecture DSL are managed externally. Consult the service owner and infrastructure team for exact deployment manifests, scaling policies, and resource limits.
