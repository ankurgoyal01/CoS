---
service: "elit-github-app"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The service is configured through the JTier/Dropwizard configuration system. The active config file is selected at runtime via the `JTIER_RUN_CONFIG` environment variable, which points to a YAML file on the container filesystem. The YAML file contains a `github` block that holds all GitHub App credentials and connection settings. Per-environment config files are baked into the container image at known paths under `/var/groupon/jtier/config/cloud/`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the active JTier YAML configuration file | yes | None | env (set per-environment in `.meta/deployment/cloud/components/api/<env>.yml`) |

### Per-environment `JTIER_RUN_CONFIG` values

| Environment | Value |
|-------------|-------|
| dev-us-west-1 | `/var/groupon/jtier/config/cloud/dev-us-west-1.yml` |
| staging-us-west-2 | `/var/groupon/jtier/config/cloud/staging-us-west-2.yml` |
| staging-us-central1 | `/var/groupon/jtier/config/cloud/staging-us-central1.yml` |
| production-us-west-1 | `/var/groupon/jtier/config/cloud/production-us-west-1.yml` |
| production-eu-west-1 | `/var/groupon/jtier/config/cloud/production-eu-west-1.yml` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `github.development` | When `true`, enables the `x-override-auth: true` header to bypass webhook signature validation | `false` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/default-elit.yml` | YAML | Default ELIT scanning rules — always applied to every PR scan. Defines `replace` regex patterns and `exclude` file patterns |
| `src/main/resources/openapi3.yml` | YAML | OpenAPI 3 source spec — used at build time for model generation only |
| `.meta/deployment/cloud/components/api/common.yml` | YAML | Shared Kubernetes deployment config — image name, port, resource requests, scaling defaults |
| `.meta/deployment/cloud/components/api/<env>.yml` | YAML | Per-environment deployment overrides — region, namespace, scaling limits, `JTIER_RUN_CONFIG` path |

### Default ELIT rule structure (`default-elit.yml`)

The default scanner configuration follows this YAML shape:

```yaml
replace:        # List of regex replacement rules
  - regex:      # Regular expression pattern to match
    alternatives: # Suggested replacement terms
exclude:        # List of regexes matching filenames to exclude from scanning
ruleFiles:      # List of additional rule files to load (supports <repo>:<file> cross-repo references)
```

Default rules include replacements for: `master`, `slave`, `black\s*list`, `white\s*list`.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `github.privateKey` | RSA private key (PKCS8 PEM format) for GitHub App JWT authentication | JTier config file (vault-injected at deploy time) |
| `github.secret` | Webhook secret for HMAC-SHA256 signature validation of inbound GitHub webhook payloads | JTier config file (vault-injected at deploy time) |
| `github.applicationId` | Numeric GitHub App ID used in JWT claims | JTier config file |
| `github.endPoint` | GitHub Enterprise API base URL | JTier config file |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **dev**: Single replica (`minReplicas: 1`, `maxReplicas: 1`). Uses a custom Hybrid Boundary subdomain (`dev`). Logs ship to the staging Kafka ELK broker.
- **staging**: Two replicas (`minReplicas: 2`, `maxReplicas: 2`). Logs ship to `kafka-elk-broker-staging.snc1`.
- **production-us-west-1**: 2–3 replicas (`minReplicas: 2`, `maxReplicas: 3`). Logs ship to `kafka-elk-broker.snc1`.
- **production-eu-west-1**: Fixed 3 replicas (`minReplicas: 3`, `maxReplicas: 3`). Logs ship to `kafka-elk-broker.dub1`.
