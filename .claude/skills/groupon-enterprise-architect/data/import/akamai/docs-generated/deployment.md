---
service: "akamai"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "none"
environments: [staging, production]
---

# Deployment

## Overview

The akamai service has no deployable application component. It is a metadata-only repository representing Groupon's ownership and operational configuration of the external Akamai SaaS platform. The actual Akamai edge infrastructure is deployed and managed entirely by Akamai, Inc. Groupon's Cyber Security team interacts with it through the Akamai control plane at `https://control.akamai.com`. WAF rules, bot management policies, and security configurations are applied through the Akamai Security Center UI and API, not through Groupon CI/CD pipelines.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Dockerfile; service is SaaS-managed |
| Orchestration | None | No Kubernetes, ECS, or Lambda manifests |
| Load balancer | Akamai (external) | Edge nodes managed by Akamai globally |
| CDN | Akamai (external) | Shared platform; CDN configuration managed by `akamai-cdn` service |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Production | Live WAF and bot management enforcement for Groupon consumer and merchant traffic | Global (Akamai edge) | `https://control.akamai.com` |
| Staging | Staging control-plane access for policy testing and configuration review | Global (Akamai edge) | `https://control.akamai.com` |

## CI/CD Pipeline

> Deployment configuration managed externally. This repository does not contain a CI/CD pipeline configuration for deploying Akamai policies. Security rule changes are applied manually through the Akamai Security Center by the Cyber Security team.

### Pipeline Stages

> Not applicable — no automated deployment pipeline exists for this service.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Managed by Akamai (SaaS) | Not configurable by Groupon |
| Memory | Managed by Akamai (SaaS) | Not configurable by Groupon |
| CPU | Managed by Akamai (SaaS) | Not configurable by Groupon |

## Resource Requirements

> Not applicable — all compute and infrastructure resources are managed by Akamai as a SaaS vendor. Groupon has no resource request or limit configurations for this service.
