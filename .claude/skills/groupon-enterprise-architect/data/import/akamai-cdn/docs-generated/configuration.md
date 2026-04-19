---
service: "akamai-cdn"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["service-yml", "akamai-control-center"]
---

# Configuration

## Overview

Akamai CDN is a managed SaaS service and does not use environment variables, config files, or secrets in the traditional application sense. Service-level metadata is defined in `.service.yml` at the repository root. Runtime CDN configuration (property rules, caching behavior, routing policies) is managed directly in Akamai Control Center (`https://control.akamai.com`). The `.service.yml` file captures operational metadata used by Groupon's Service Portal and OpsConfig systems.

## Environment Variables

> Not applicable — this service is a managed SaaS configuration unit with no application runtime. No environment variables are used.

## Feature Flags

> Not applicable — no feature flag infrastructure is used by this service.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.service.yml` | YAML | Service Portal / ORR compliance metadata; defines service name, title, SRE contacts, dashboard URLs, environment URLs, and status endpoint configuration |
| `architecture/workspace.dsl` | Structurizr DSL | Architecture-as-code model for the Akamai CDN service within the Continuum platform |
| `architecture/models/components/akamai-cdn-service.dsl` | Structurizr DSL | Container and component definitions for `continuumAkamaiCdn` |
| `architecture/models/relations.dsl` | Structurizr DSL | External relationship: `continuumAkamaiCdn` to `akamai` via HTTPS |
| `architecture/models/components-relations.dsl` | Structurizr DSL | Internal component relationship: `akamaiCdnConfiguration` to `akamaiCdnObservability` |
| `architecture/views/dynamics/cdn-ops.dsl` | Structurizr DSL | Dynamic view for the Akamai CDN Operations Flow |

## Secrets

> Not applicable — no secrets are managed within this repository. Akamai API credentials (EdgeGrid keys) used for automation are managed externally by the SRE team and stored outside this codebase.

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The `.service.yml` defines two environments under the `snc1` colo:

| Environment | Base URL Type | Value |
|-------------|--------------|-------|
| production | external | `https://control.akamai.com` |
| staging | internal | `https://control.akamai.com` |

Both environments point to the same Akamai Control Center — staging and production CDN configurations are separated within Akamai's own property management system (different Akamai property configurations or staging edge hostnames), not at the Groupon infrastructure level.

The service has `status_endpoint: disabled: true` — no HTTP status endpoint exists for this service, as it is a managed SaaS configuration boundary rather than an HTTP server. Schema validation is also disabled (`schema: disabled`).
