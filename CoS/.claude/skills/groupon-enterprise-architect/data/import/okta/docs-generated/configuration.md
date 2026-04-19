---
service: "okta"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

The Okta service configuration is primarily managed through external tooling (Okta tenant administration) and the PostgreSQL configuration store (`continuumOktaConfigStore`). No application-level config files, environment variable definitions, or secrets manifests are present in the federated repository snapshot. The `.service.yml` provides service registry metadata including endpoint URLs for production and staging environments.

## Environment Variables

> No evidence found in codebase. No environment variable definitions are present in the repository snapshot. Configuration such as Okta client credentials, database connection strings, and API secrets are expected to be injected at runtime via environment variables or a secrets manager, but specific variable names are not available in the DSL or service metadata.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.service.yml` | YAML | Service registry metadata: name, team, endpoints, SRE contacts, PagerDuty integration |

## Secrets

> No evidence found in codebase. Secrets (Okta client ID, client secret, database credentials) are expected to be managed via a secrets store, but no specific secret names or stores are defined in the available artifacts.

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The `.service.yml` defines two environments:

- **Production**: External endpoint `https://groupon.okta.com`
- **Staging**: External endpoint `https://grouponsandbox.okta.com/`

Specific per-environment configuration overrides beyond endpoint URLs are not present in the repository snapshot.
