---
service: "corpAD"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [ops-config, group-policy, service-yml]
---

# Configuration

## Overview

corpAD is an infrastructure service managed by the Syseng team. Configuration is not driven by application environment variables or a software config file in a codebase. Instead, it is controlled by:

- **Active Directory Group Policy Objects (GPOs)**: Domain-wide and OU-scoped policy settings (password policies, audit policies, Kerberos ticket lifetime, etc.)
- **Active Directory domain controller configuration**: Replication topology, site and subnet assignments, DNS integration
- **Service metadata** (`.service.yml`): Registers the service in Groupon's service registry with VIP base URLs and SRE contact information
- **Hosting**: `hosting_configured_via_ops_config: false` — the service is not managed through the standard ops-config pipeline

Per the `.service.yml`, the `status_endpoint` is disabled (`disabled: true`) and schema validation is disabled (`schema: disabled`), indicating corpAD does not conform to the standard Groupon service health-check and schema discovery conventions.

## Environment Variables

> No evidence found in codebase. corpAD is an infrastructure service with no application codebase. Configuration is managed via Active Directory administration tools and Group Policy, not environment variables.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.service.yml` | YAML | Groupon service registry metadata — name, title, description, SRE contacts, colo VIP base URLs, team membership, and external documentation links |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Workday sync service account credentials | Authenticates the AD sync process to Workday for employee data import | Managed by Syseng operations (details in Confluence Owners Manual) |
| LDAP bind service account credentials | Used by consuming services (e.g., killbill, ARQWeb, openvpn-config) to authenticate LDAP queries | Managed per-consumer in each service's secret store |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

corpAD runs in production only across three colos. There is no staging or development instance documented in `.service.yml`. Per-colo VIP configuration:

| Colo | Internal Base URL |
|------|-------------------|
| snc1 | `https://corpldap1.snc1` |
| dub1 | `https://corpldap1.dub1` |
| sac1 | `https://corpldap1.sac1` |

Consumers select the appropriate colo VIP based on their own deployment location to minimize cross-colo LDAP latency.
