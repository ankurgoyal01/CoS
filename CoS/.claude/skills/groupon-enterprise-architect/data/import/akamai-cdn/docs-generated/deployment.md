---
service: "akamai-cdn"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "saas"
environments: ["staging", "production"]
---

# Deployment

## Overview

Akamai CDN is a managed SaaS platform — Groupon does not deploy, containerize, or orchestrate any application for this service. Deployment in this context means applying CDN configuration changes (property rules, caching policies, routing settings) to the Akamai edge network via the Akamai Control Center. The `akamai-cdn` repository acts as the architecture-as-code definition for Groupon's Akamai operational boundary; the actual CDN infrastructure is fully managed by Akamai.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Dockerfile — managed SaaS, not a containerized application |
| Orchestration | Akamai Edge Platform (SaaS) | Akamai manages edge node deployment globally |
| Load balancer | Akamai (edge) | Akamai provides built-in global load balancing and traffic routing |
| CDN | Akamai | Primary CDN provider; managed via `https://control.akamai.com` |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| production | Live Groupon consumer and merchant traffic | Global (Akamai edge network) | `https://control.akamai.com` |
| staging | Pre-production CDN configuration testing | Global (Akamai staging edge) | `https://control.akamai.com` |

Both environments are managed within Akamai's platform under the `snc1` colo definition in `.service.yml`. Staging and production configurations are separated within Akamai's property management system.

## CI/CD Pipeline

> No evidence found of an automated CI/CD pipeline for deploying CDN configuration changes. Configuration changes are applied manually by the SRE cloud-routing team via the Akamai Control Center UI or Akamai OPEN API. The architecture DSL changes in this repository are validated and published by the central architecture CI pipeline (`.github/workflows/architecture-docs.yml` in the parent architecture repo).

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Managed by Akamai (global edge network, 300,000+ servers) | Akamai SLA-governed |
| Memory | Not applicable — SaaS | N/A |
| CPU | Not applicable — SaaS | N/A |

## Resource Requirements

> Not applicable — Akamai CDN is a managed SaaS platform. Groupon has no compute resource configuration responsibilities for this service.

> Deployment configuration managed externally (by Akamai).
