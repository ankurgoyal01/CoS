---
service: "layout-service"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, helm-values]
---

# Configuration

## Overview

Layout Service follows the i-tier Node.js configuration convention: environment variables injected at container startup, with Kubernetes/Helm values providing per-environment overrides. There is no runtime config store (no Consul or Vault agent sidecar evidenced in the architecture inventory). Secrets are injected as environment variables via Kubernetes secrets.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Sets runtime environment mode (development, staging, production) | yes | `production` | env |
| `PORT` | HTTP port the service listens on | yes | `3000` | env |
| `REDIS_URL` | Connection string for `continuumLayoutTemplateCache` (Redis) | yes | none | env / k8s-secret |
| `CDN_BASE_URL` | Base URL for CDN-backed static asset resolution used by `layoutSvc_assetResolver` | yes | none | env / helm |
| `LOG_LEVEL` | Controls log verbosity | no | `info` | env |
| `TEMPLATE_CACHE_TTL` | TTL (in seconds) for cached template entries in Redis | no | service default | env / helm |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

> Specific variable names above are inferred from the architecture inventory and i-tier Node.js conventions. Authoritative values are maintained in the service's Helm chart and Kubernetes secret manifests.

## Feature Flags

> No evidence found of a feature flag system integration in the architecture inventory. Layout context assembly (`layoutSvc_requestComposer`) may evaluate request-level context signals, but no named flags are exposed through an external flag service.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| Helm `values.yaml` | YAML | Per-environment Kubernetes deployment values (replicas, resource limits, env overrides) |
| itier-server config | JSON/JS | Framework-level routing and middleware configuration loaded at startup |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `REDIS_URL` | Redis connection string including credentials for `continuumLayoutTemplateCache` | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: `NODE_ENV=development`; local Redis instance; CDN base URL points to local or staging asset host
- **Staging**: `NODE_ENV=staging`; shared staging Redis cluster; CDN base URL points to staging CDN
- **Production**: `NODE_ENV=production`; production Redis cluster provisioned per region; CDN base URL points to production Akamai/CloudFront origin; replica count scaled per traffic profile
