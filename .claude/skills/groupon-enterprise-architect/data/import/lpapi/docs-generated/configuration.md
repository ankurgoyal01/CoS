---
service: "lpapi"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

LPAPI is configured through Dropwizard YAML configuration files, supplemented by environment variable overrides per deployment environment. Capistrano manages deployment and environment-specific config file promotion. The service follows the JTier configuration pattern common to Continuum Platform services.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | JDBC connection string for the primary PostgreSQL datastore | yes | none | env |
| `DATABASE_READONLY_URL` | JDBC connection string for the read-only PostgreSQL replica | yes | none | env |
| `TAXONOMY_SERVICE_URL` | Base URL for the Taxonomy Service HTTP client | yes | none | env |
| `RELEVANCE_API_URL` | Base URL for the Relevance API (RAPI) HTTP client | yes | none | env |
| `UGC_SERVICE_URL` | Base URL for the UGC Service HTTP client | yes | none | env |
| `GSC_API_CREDENTIALS` | Credentials reference for Google Search Console API access | no | none | env |
| `AUTO_INDEX_ENABLED` | Enables or disables the Auto Indexer worker process | no | false | env |
| `UGC_SYNC_ENABLED` | Enables or disables the UGC Worker synchronization process | no | false | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `AUTO_INDEX_ENABLED` | Controls whether the Auto Indexer background worker runs | false | global |
| `UGC_SYNC_ENABLED` | Controls whether the UGC Worker background sync runs | false | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | yaml | Main Dropwizard application configuration (server, database, clients, logging) |
| `config-{env}.yml` | yaml | Per-environment overrides (dev, staging, production) — managed by Capistrano |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_PASSWORD` | PostgreSQL primary database password | env / deployment secrets |
| `DATABASE_READONLY_PASSWORD` | PostgreSQL read-only replica password | env / deployment secrets |
| `GSC_API_CREDENTIALS` | Google Search Console service account credentials | env / deployment secrets |

> Secret values are NEVER documented. Only names and rotation policies are listed here.

## Per-Environment Overrides

Capistrano deploys environment-specific configuration files alongside the application artifact. Typical environment differences:

- **Development**: Local PostgreSQL instance; Taxonomy Service, RAPI, and UGC Service pointed at staging endpoints; Auto Indexer and UGC Worker disabled
- **Staging**: Staging PostgreSQL instances; all downstream services pointed at staging endpoints; workers optionally enabled for integration testing
- **Production**: Production PostgreSQL primary/replica pair; all downstream services pointed at production endpoints; worker enabled flags set per operational schedule
