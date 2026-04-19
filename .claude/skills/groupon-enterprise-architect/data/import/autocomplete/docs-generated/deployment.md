---
service: "autocomplete"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "continuum-platform"
environments: [development, staging, production]
---

# Deployment

## Overview

The autocomplete service is a Java 21 Dropwizard application deployed as part of the Continuum platform. It uses a Maven-built JAR with embedded Jetty server (standard Dropwizard deployment model). The embedded term files are packaged inside the artifact. Deployment configuration is managed externally by the Continuum platform deployment toolchain.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Java JAR (Dropwizard embedded Jetty) | Maven-built artifact; `jtier-service-pom` parent |
| Orchestration | Continuum platform (JTier) | Deployment configuration managed externally |
| Load balancer | No evidence found in codebase | |
| CDN | No evidence found in codebase | |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and integration testing | — | — |
| Staging | Pre-production validation | — | — |
| Production | Live traffic serving Consumer Apps | — | — |

> Environment-specific URLs and regions are managed externally and are not defined in the architecture model.

## CI/CD Pipeline

- **Tool**: No evidence found in codebase
- **Config**: No evidence found in codebase
- **Trigger**: No evidence found in codebase

### Pipeline Stages

> Deployment configuration managed externally. Pipeline details are not defined in the architecture module of this repository.

## Scaling

> No evidence found in codebase. Scaling configuration is managed externally by the Continuum platform deployment toolchain.

## Resource Requirements

> No evidence found in codebase. Resource requests and limits are managed externally by the Continuum platform deployment toolchain.
