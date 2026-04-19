---
service: "akamai"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files]
---

# Configuration

## Overview

All configuration for the akamai service is declared in a single YAML file, `.service.yml`, at the root of the repository. This file defines service identity, team ownership, SRE notification channels, environment base URLs, and security dashboard links. There are no environment variables, no application secrets, and no external config stores (Consul, Vault, Helm) — the repository is a metadata-only configuration artifact managed by the Cyber Security team.

## Environment Variables

> Not applicable — this service has no runtime application and therefore no environment variables.

## Feature Flags

> Not applicable — no feature flags are defined or referenced in this repository.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.service.yml` | YAML | Primary service metadata: name, title, description, team ownership, SRE contacts, mailing list, colo/environment base URLs, documentation links, and dashboard references |

### `.service.yml` Key Sections

| Section | Purpose |
|---------|---------|
| `name` / `title` / `description` | Service identity: `akamai` / `Akamai Product Security` / security platform description |
| `documentation` | Links to the Akamai Owners Manual on Confluence (`https://groupondev.atlassian.net/wiki/spaces/SECURITY/pages/80750706765/`) |
| `sre.notify` | Emergency notification email: `infosec@groupon.com` |
| `sre.dashboards` | Three Akamai Security Center dashboard URLs (config selector `85902`, account `AANA-67IW3O`) |
| `mailing_list` | Announcement list: `akamai@groupon.com` |
| `team.name` | `Cyber Security` |
| `team.owner` | `c_anemeth` |
| `team.members` | `c_jdiaz`, `c_wkura`, `c_pnowicki`, `sbhatt` |
| `team.email` | `infosec@groupon.com` |
| `colos.snc1.environments.production.base_urls.external` | `https://control.akamai.com` |
| `colos.snc1.environments.staging.base_urls.internal` | `https://control.akamai.com` |
| `status_endpoint.disabled` | `true` — status endpoint is intentionally disabled |
| `schema` | `disabled` — schema validation is not applicable |

## Secrets

> Not applicable — no secrets are defined in this repository. Akamai account credentials (used to access `https://control.akamai.com`) are managed externally by the Cyber Security team outside this codebase.

## Per-Environment Overrides

Both staging and production environments point to the same Akamai control-plane base URL (`https://control.akamai.com`), differentiated only by the `external` vs. `internal` URL key:

- **Production**: `colos.snc1.environments.production.base_urls.external = https://control.akamai.com`
- **Staging**: `colos.snc1.environments.staging.base_urls.internal = https://control.akamai.com`
