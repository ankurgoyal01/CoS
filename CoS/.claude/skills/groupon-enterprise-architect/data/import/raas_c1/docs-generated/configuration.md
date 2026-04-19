---
service: "raas_c1"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [service-portal-yml]
---

# Configuration

## Overview

RAAS C1 configuration is defined entirely within the Service Portal manifest (`.service.yml`). There are no application environment variables, config files, or secrets because this entry carries no deployable runtime process. The manifest registers colo-scoped base URLs, SRE contacts, team membership, documentation links, and the single `raas_dns` dependency.

## Environment Variables

> Not applicable — this service has no deployable application and no environment variables.

## Feature Flags

> Not applicable — no feature flags are defined or consumed.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.service.yml` | YAML | Service Portal manifest — registers service identity, colo base URLs, SRE contacts, team ownership, subservices, and dependencies |

### Key fields in `.service.yml`

| Field | Value | Purpose |
|-------|-------|---------|
| `name` | `raas_c1` | Service identifier in the Service Portal |
| `title` | `Redis as a Service (raas) - C1` | Human-readable service name |
| `schema` | `disabled` | No schema validation endpoint |
| `status_endpoint.disabled` | `true` | Health check endpoint is disabled |
| `colos.snc1.environments.production.base_urls.internal` | `https://us.raas-bast-cs-prod.grpn:8443` | Internal base URL for snc1 production |
| `colos.sac1.environments.production.base_urls.internal` | `https://us.raas-bast-cs-prod.grpn:8443` | Internal base URL for sac1 production |
| `colos.dub1.environments.production.base_urls.internal` | `https://dub1.raas-bast-cs-prod.grpn:8443` | Internal base URL for dub1 production |
| `dependencies` | `raas_dns` | Single declared service dependency |
| `sre.notify` | `raas-pager@groupon.com` | SRE alert routing |
| `sre.slack_channel_id` | `CFA7KUDGV` (redis-memcached) | Slack channel for operational communication |

## Secrets

> Not applicable — no secrets are managed by this Service Portal entry.

## Per-Environment Overrides

Production is the only registered environment. The snc1 and sac1 colos share the base URL `https://us.raas-bast-cs-prod.grpn:8443` while dub1 uses `https://dub1.raas-bast-cs-prod.grpn:8443`. No staging or development environments are registered for this entry.
