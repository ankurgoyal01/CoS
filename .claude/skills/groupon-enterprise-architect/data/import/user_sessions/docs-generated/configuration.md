---
service: "user_sessions"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

user_sessions is configured exclusively via environment variables injected at runtime. No external config store (Consul, Vault) is explicitly evidenced in the inventory. Secrets (OAuth client credentials, session secret) are expected to be injected via Kubernetes secrets or a secrets manager and surfaced as environment variables.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment mode (development, staging, production); controls logging verbosity and feature behavior | yes | `production` (inferred) | env |
| `GRAPHQL_ENDPOINT` | Base URL of the GAPI GraphQL endpoint used for all upstream user/session operations | yes | None | env |
| `MEMCACHED_HOSTS` | Comma-separated list of Memcached host:port addresses for session storage | yes | None | env |
| `SESSION_SECRET` | Secret key used to sign session cookies | yes | None | env / k8s-secret |
| `FEATURE_FLAGS` | Feature flag configuration controlling conditional behavior (e.g., social login enablement, A/B variants) | no | None | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `FEATURE_FLAGS` | Controls conditional features such as social login provider availability and UI variants | No evidence of individual flag names in inventory | No evidence found |

> Individual flag names within the `FEATURE_FLAGS` configuration are not discoverable from the inventory. See service owner for the full flag catalogue.

## Config Files

> No evidence found in codebase of service-level config files (YAML, TOML, JSON) beyond `package.json` (dependency manifest) and webpack configuration for asset bundling.

| File | Format | Purpose |
|------|--------|---------|
| `package.json` | JSON | Node.js dependency manifest and npm script definitions |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SESSION_SECRET` | Signs and verifies session cookies to prevent tampering | k8s-secret (inferred) |
| Google OAuth client credentials | Client ID and secret for Google OAuth 2.0 authorization flow | k8s-secret (inferred) |
| Facebook OAuth client credentials | Client ID and secret for Facebook OAuth 2.0 authorization flow | k8s-secret (inferred) |
| GAPI service credentials | Authentication for service-to-service GAPI calls | k8s-secret (inferred) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

`NODE_ENV` drives environment-specific behavior. In `development` and staging environments, `GRAPHQL_ENDPOINT` and `MEMCACHED_HOSTS` point to non-production GAPI instances and Memcached clusters. Production deployments across US (us-west-1/2, us-central1) and EU (europe-west1, eu-west-1) regions use region-specific values for `MEMCACHED_HOSTS` and `GRAPHQL_ENDPOINT` to ensure traffic stays within the same geographic region.
