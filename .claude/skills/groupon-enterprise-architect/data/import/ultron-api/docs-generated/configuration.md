---
service: "ultron-api"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

ultron-api follows standard Play Framework configuration patterns. Application settings are defined in `application.conf` (HOCON format), with environment-specific values injected via environment variables or system properties at runtime. Database connections for both the Ultron Database and the Quartz Scheduler DB are configured separately. SMTP credentials for the Email Manager are injected as secrets.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ULTRON_DB_URL` | JDBC connection URL for `continuumUltronDatabase` | yes | none | env / vault |
| `ULTRON_DB_USER` | Database username for `continuumUltronDatabase` | yes | none | env / vault |
| `ULTRON_DB_PASSWORD` | Database password for `continuumUltronDatabase` | yes | none | vault |
| `QUARTZ_DB_URL` | JDBC connection URL for `continuumQuartzSchedulerDb` | yes | none | env / vault |
| `QUARTZ_DB_USER` | Database username for `continuumQuartzSchedulerDb` | yes | none | env / vault |
| `QUARTZ_DB_PASSWORD` | Database password for `continuumQuartzSchedulerDb` | yes | none | vault |
| `SMTP_HOST` | SMTP server hostname for alert email delivery | yes | none | env |
| `SMTP_PORT` | SMTP server port | yes | 25 | env |
| `SMTP_USER` | SMTP authentication username | no | none | env / vault |
| `SMTP_PASSWORD` | SMTP authentication password | no | none | vault |
| `APPLICATION_SECRET` | Play Framework application secret for session signing | yes | none | vault |
| `JAVA_OPTS` | JVM startup options (heap size, GC settings) | no | — | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed above.

## Feature Flags

> No evidence found in codebase. ultron-api does not appear to use a remote feature flag service. Behavioral configuration is managed via `application.conf` properties.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `conf/application.conf` | HOCON | Primary Play Framework application configuration |
| `conf/routes` | Play routes DSL | HTTP route definitions mapping paths to controllers |
| `conf/evolutions/default/*.sql` | SQL | Play Evolutions database schema migration scripts |
| `conf/quartz.properties` | Properties | Quartz scheduler configuration (job store, thread pool) |

> Config file paths are inferred from standard Play Framework project conventions. Verify against the service source repository.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `ULTRON_DB_PASSWORD` | Authenticates to the Ultron metadata database | vault |
| `QUARTZ_DB_PASSWORD` | Authenticates to the Quartz scheduler database | vault |
| `SMTP_PASSWORD` | Authenticates SMTP email sending (if required) | vault |
| `APPLICATION_SECRET` | Signs Play session cookies and CSRF tokens | vault |

> Secret values are NEVER documented. Only names and rotation policies are listed here.

## Per-Environment Overrides

Standard Continuum environments: development, staging, and production. Database URLs and SMTP hosts differ per environment. Staging environments typically point to staging database instances and may use a mock or sandbox SMTP server. Production uses live database clusters and the production SMTP relay.
