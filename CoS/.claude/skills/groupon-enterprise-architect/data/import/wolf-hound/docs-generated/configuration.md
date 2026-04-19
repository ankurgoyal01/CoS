---
service: "wolf-hound"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, helm-values]
---

# Configuration

## Overview

Wolfhound Editor UI is configured primarily through environment variables injected at container start time. Kubernetes Helm values provide environment-specific overrides. No evidence of a runtime config store (Consul, Vault) is available from the architecture model alone.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `PORT` | HTTP port the Express server listens on | no | `3000` | env |
| `NODE_ENV` | Runtime environment designation (`development`, `production`) | yes | — | env |
| `WOLFHOUND_API_URL` | Base URL for `continuumWolfhoundApi` | yes | — | env |
| `USERS_API_URL` | Base URL for `continuumWhUsersApi` | yes | — | env |
| `LPAPI_URL` | Base URL for `continuumLpapiService` | yes | — | env |
| `MECS_URL` | Base URL for `continuumMarketingEditorialContentService` | yes | — | env |
| `DEALS_API_URL` | Base URL for `continuumMarketingDealService` | yes | — | env |
| `CLUSTERS_API_URL` | Base URL for `continuumDealsClusterService` | yes | — | env |
| `RELEVANCE_API_URL` | Base URL for `continuumRelevanceApi` | yes | — | env |
| `BHUVAN_URL` | Base URL for `continuumBhuvanService` | yes | — | env |
| `SESSION_SECRET` | Secret key for Express session signing | yes | — | env / k8s-secret |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

> The exact variable names above are inferred from the integration landscape described in the architecture model. Confirm names against the actual deployment manifests.

## Feature Flags

> No evidence found for a runtime feature flag system.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `package.json` | JSON | npm dependency manifest and npm scripts |
| Helm `values.yaml` (per environment) | YAML | Kubernetes deployment overrides (replicas, resource limits, env var injection) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SESSION_SECRET` | Express session signing key | k8s-secret |
| Upstream service credentials | Auth tokens or API keys for internal service calls (if required) | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: `NODE_ENV=development`; upstream service URLs point to local or staging endpoints; debug logging enabled.
- **Staging**: `NODE_ENV=production`; upstream URLs point to staging Continuum services; used for integration testing.
- **Production**: `NODE_ENV=production`; upstream URLs point to production Continuum services; session secrets managed via Kubernetes secrets.
