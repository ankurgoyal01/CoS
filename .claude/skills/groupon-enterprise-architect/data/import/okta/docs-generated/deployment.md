---
service: "okta"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: ""
environments: [production, staging]
---

# Deployment

## Overview

The Okta service deployment details are managed externally. The `.service.yml` service registry defines two environments — production and staging — each with a corresponding Okta tenant endpoint. No Dockerfile, Kubernetes manifests, Helm charts, or CI/CD pipeline configuration files are present in the federated repository snapshot. The service is a Continuum Platform integration service; infrastructure provisioning is expected to be managed by the Okta team and SRE.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Not specified | No Dockerfile found in repository snapshot |
| Orchestration | Not specified | No Kubernetes or ECS manifests found |
| Load balancer | Not specified | No load balancer configuration found |
| CDN | Not specified | No CDN configuration found |

> Deployment configuration managed externally.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| production | Live Okta tenant for Groupon | Not specified | https://groupon.okta.com |
| staging | Sandbox Okta tenant for testing | Not specified | https://grouponsandbox.okta.com/ |

## CI/CD Pipeline

> No evidence found in codebase. No CI/CD pipeline configuration files are present in the repository snapshot.

### Pipeline Stages

> No evidence found in codebase.

## Scaling

> No evidence found in codebase. Scaling configuration is not defined in the available repository artifacts.

## Resource Requirements

> No evidence found in codebase. Resource requests and limits are not defined in the available repository artifacts.
