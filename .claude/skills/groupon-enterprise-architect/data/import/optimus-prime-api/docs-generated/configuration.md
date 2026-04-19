---
service: "optimus-prime-api"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars, vault]
---

# Configuration

## Overview

Optimus Prime API is configured through JTier/Dropwizard application YAML files, with secrets and environment-specific values injected at deploy time via the Continuum platform. Connection credentials for data sources (SFTP, Hive, BigQuery) are stored encrypted in the PostgreSQL database rather than in flat configuration files. Database schema changes are applied automatically at startup via Flyway.

## Environment Variables

> No evidence found in codebase. Specific environment variable names are not defined in the architecture model. The following categories of values are expected to be injected at deploy time:

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| PostgreSQL connection URL and credentials | `continuumOptimusPrimeApiDb` connectivity | yes | none | env / vault |
| NiFi base URL and credentials | `continuumOptimusPrimeNifi` API access | yes | none | env / vault |
| LDAP/Active Directory URL and bind credentials | User authentication and group resolution | yes | none | env / vault |
| SMTP relay host and credentials | Email notification delivery | yes | none | env / vault |
| GCS credentials (service account) | `continuumOptimusPrimeGcsBucket` access | yes | none | env / vault |
| AWS credentials | `continuumOptimusPrimeS3Storage` access | yes | none | env / vault |
| Google Sheets API service account credentials | Metadata retrieval | yes | none | env / vault |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. No external feature flag system is referenced in the architecture model. Quartz job schedules and NiFi integration behavior may be tuned via application config rather than flags.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| JTier application YAML | YAML | Static service configuration: server port, logging, thread pools, database pool settings, Quartz configuration |
| Flyway migration files | SQL | Database schema versioning and migrations applied at service startup via `jtier-migrations` |
| FreeMarker templates | FTL | Email and notification message templates rendered by `notificationAdapter` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| PostgreSQL password | Database authentication | vault / env |
| NiFi API credentials | NiFi process group management | vault / env |
| LDAP bind password | Active Directory authentication | vault / env |
| SMTP credentials | Email relay authentication | vault / env |
| GCS service account key | Google Cloud Storage access | vault / env |
| AWS access key / secret | S3 storage access | vault / env |
| Google Sheets service account key | Spreadsheet metadata access | vault / env |
| Per-connection encrypted credentials | User-defined data source credentials stored encrypted in PostgreSQL | postgresql / vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

> No evidence found in codebase. Environment-specific differences (dev, staging, production) are managed externally by the Continuum platform deployment toolchain. Database connection URLs, NiFi cluster addresses, and external service endpoints differ per environment.
