---
service: "itier-3pip"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, helm-values]
---

# Configuration

## Overview

itier-3pip is configured primarily via environment variables injected at runtime by Kubernetes/Helm. Provider API credentials, internal service endpoints, Memcached connection details, and observability settings are all expected to be externalized. No configuration management system (Consul, Vault) is referenced explicitly in the architecture model; secrets are expected to be managed via Kubernetes secrets mounted as environment variables.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment (production, staging, development) | yes | `production` | env |
| `PORT` | HTTP server listen port | yes | `3000` | env |
| `MEMCACHED_HOSTS` | Comma-separated list of Memcached host:port endpoints | yes | — | env / helm |
| `TPIS_BASE_URL` | Base URL for the TPIS service (`continuumThirdPartyInventoryService`) | yes | — | env / helm |
| `DEAL_CATALOG_BASE_URL` | Base URL for the Deal Catalog service (`continuumDealCatalogService`) | yes | — | env / helm |
| `ORDERS_BASE_URL` | Base URL for the Orders service (`continuumOrdersService`) | yes | — | env / helm |
| `EPODS_BASE_URL` | Base URL for the ePODS service (`continuumEpodsService`) | yes | — | env / helm |
| `GROUPON_V2_BASE_URL` | Base URL for Groupon V2 Users/Deals/Accounts APIs | yes | — | env / helm |
| `VIATOR_API_KEY` | API key for Viator provider integration | yes | — | k8s-secret |
| `PEEK_API_KEY` | API key for Peek provider integration | yes | — | k8s-secret |
| `AMC_API_KEY` | API key for AMC provider integration | yes | — | k8s-secret |
| `VIVID_API_KEY` | API key for Vivid provider integration | yes | — | k8s-secret |
| `GRUBHUB_API_KEY` | API key for Grubhub provider integration | yes | — | k8s-secret |
| `MINDBODY_API_KEY` | API key for Mindbody provider integration | yes | — | k8s-secret |
| `HBW_API_KEY` | API key for HBW provider integration | yes | — | k8s-secret |
| `LOG_LEVEL` | Logging verbosity for `groupon-steno` | no | `info` | env |

> IMPORTANT: Secret values are never documented. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found of a feature flag system in the architecture model. Feature gating, if used, is expected to be managed at the application level via environment variable conventions or inline configuration.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `package.json` | JSON | Node.js dependency manifest and npm scripts |
| `webpack.config.js` | JavaScript | Webpack build configuration for client-side bundle |
| Helm values file | YAML | Kubernetes deployment configuration (replicas, resources, env injection) — managed externally via napistrano |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `VIATOR_API_KEY` | Authenticates outbound requests to Viator API | k8s-secret |
| `PEEK_API_KEY` | Authenticates outbound requests to Peek API | k8s-secret |
| `AMC_API_KEY` | Authenticates outbound requests to AMC API | k8s-secret |
| `VIVID_API_KEY` | Authenticates outbound requests to Vivid API | k8s-secret |
| `GRUBHUB_API_KEY` | Authenticates outbound requests to Grubhub API | k8s-secret |
| `MINDBODY_API_KEY` | Authenticates outbound requests to Mindbody API | k8s-secret |
| `HBW_API_KEY` | Authenticates outbound requests to HBW API | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies are listed here.

## Per-Environment Overrides

`NODE_ENV` controls environment-specific behavior. Internal service base URLs, Memcached hosts, and provider API endpoints differ between development, staging, and production environments and are injected via Helm values at deploy time. The Docker image itself is environment-agnostic (alpine-node12 base); all environment differences are externalized.
