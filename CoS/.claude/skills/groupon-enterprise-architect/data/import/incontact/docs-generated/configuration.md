---
service: "incontact"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [service-yml]
---

# Configuration

## Overview

InContact is a vendor-managed SaaS platform. No application configuration files (environment variable declarations, Helm values, Consul entries, Vault paths, or config YAML/TOML) are present in this repository. The only structured configuration artifact is `.service.yml`, which captures service registry metadata: ownership, team contacts, SRE routing, and declared dependencies.

## Environment Variables

> No evidence found in codebase.

No environment variables are declared in this repository.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.service.yml` | YAML | Service registry metadata — ownership, team, SRE on-call routing, declared dependencies (`ogwall`, `global_support_systems`), and documentation links |

### `.service.yml` Key Fields

| Field | Value | Purpose |
|-------|-------|---------|
| `name` | `incontact` | Service identifier in the Groupon service registry |
| `title` | `InContact` | Human-readable display name |
| `description` | `SaaS Platform` | Short service description |
| `branch` | `master` | Primary branch tracked by architecture federation |
| `team.name` | `gss` | Owning team identifier |
| `team.owner` | `flueck` | Primary service owner |
| `team.email` | `gss@groupon.com` | Team group email alias |
| `sre.notify` | `gss-dev@groupon.pagerduty.com` | SRE PagerDuty alert target |
| `sre.pagerduty` | `https://groupon.pagerduty.com/services/PN9TCKJ` | PagerDuty service URL |
| `sre.slack_channel_id` | `CFED5CCSV` | Slack on-call channel |
| `sre.gchat_space_id` | `AAAArQs1V3g` | Google Chat space |
| `dependencies` | `ogwall`, `global_support_systems` | Declared internal service dependencies |
| `schema` | `disabled` | Schema registration not active |
| `status_endpoint.disabled` | `true` | Status endpoint not exposed |

## Secrets

> No evidence found in codebase.

## Per-Environment Overrides

> No evidence found in codebase.

Per-environment configuration for the InContact SaaS platform is managed by NICE inContact and the GSS team outside of this repository.
