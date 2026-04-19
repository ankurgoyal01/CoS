---
service: "metro-ui"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, helm-values]
---

# Configuration

## Overview

Metro UI is configured primarily through environment variables injected at container runtime by Kubernetes/Helm. The itier-server framework handles service discovery and downstream client configuration. Multi-region deployment (US and EU) is managed via environment-specific Helm value overrides.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment (production, staging, development) | yes | none | env |
| `PORT` | HTTP port the itier-server process listens on | yes | none | env |
| `API_PROXY_URL` | Base URL for `apiProxy` backend routing | yes | none | helm |
| `DEAL_MANAGEMENT_API_URL` | Base URL for `continuumDealManagementApi` | yes | none | helm |
| `GEO_DETAILS_SERVICE_URL` | Base URL for `continuumGeoDetailsService` | yes | none | helm |
| `M3_PLACES_SERVICE_URL` | Base URL for `continuumM3PlacesService` | yes | none | helm |
| `MARKETING_DEAL_SERVICE_URL` | Base URL for `continuumMarketingDealService` | yes | none | helm |
| `GTM_CONTAINER_ID` | Google Tag Manager container ID for analytics tag injection | yes | none | helm |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

> Note: Exact variable names above are inferred from service inventory and standard itier conventions. Confirm against the Helm values files and itier-server configuration for the authoritative list.

## Feature Flags

> No evidence found of a feature flag system (e.g., LaunchDarkly, Unleash, or custom flags) in the service inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `package.json` | JSON | Node.js dependency manifest and npm scripts |
| `Dockerfile` | Dockerfile | Container image definition (alpine-node14.19.1 base) |
| Helm values (external) | YAML | Per-environment Kubernetes deployment configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| itier service credentials | Authentication tokens for internal itier service-to-service calls | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Local Node.js process with mock or local-stub downstream services
- **Staging**: Kubernetes deployment targeting staging-tier Continuum services; canary traffic routing via Harness
- **Production (US)**: Kubernetes multi-region US deployment with production Continuum service URLs
- **Production (EU)**: Kubernetes multi-region EU deployment with EU-region Continuum service URLs; data residency requirements enforced via region-specific Helm values
