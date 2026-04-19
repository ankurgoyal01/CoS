---
service: "ARQWeb"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "unknown"
environments: ["production"]
---

# Deployment

## Overview

ARQWeb consists of two separately deployed processes: the Flask/uWSGI web application (`continuumArqWebApp`) and the Python background worker (`continuumArqWorker`). Both processes share the same PostgreSQL database (`continuumArqPostgres`). The service is part of the Continuum Platform. Specific container orchestration, Kubernetes manifests, or CI/CD pipeline configuration files were not present in the repository inventory — deployment configuration is managed externally.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Web process | Python Flask / uWSGI | WSGI application server serving HTTP requests |
| Worker process | Python Worker | Long-running cron loop process for background jobs |
| Database | PostgreSQL | Shared relational store for both processes |
| Container | Docker (assumed) | No Dockerfile found in repository inventory |
| Orchestration | Unknown | No Kubernetes manifests or ECS task definitions found in repository inventory |
| Load balancer | Unknown | No load balancer configuration found in repository inventory |
| CDN | Unknown | No CDN configuration found in repository inventory |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Production | Live internal access request system | Unknown | Internal Groupon network only |

> Deployment configuration managed externally. Environment details not discoverable from the architecture model or repository inventory.

## CI/CD Pipeline

- **Tool**: No evidence found in codebase
- **Config**: No evidence found in codebase
- **Trigger**: No evidence found in codebase

### Pipeline Stages

> No evidence found in codebase. Deployment pipeline stages are not described in the architecture model.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Unknown | No evidence found in codebase |
| Memory | Unknown | No evidence found in codebase |
| CPU | Unknown | No evidence found in codebase |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | No evidence found | No evidence found |
| Memory | No evidence found | No evidence found |
| Disk | No evidence found | No evidence found |

> Deployment configuration managed externally. Resource requirements are not discoverable from the architecture model alone.
