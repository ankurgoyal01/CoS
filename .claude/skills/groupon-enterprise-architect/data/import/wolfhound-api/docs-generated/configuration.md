---
service: "wolfhound-api"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Wolfhound API is a Dropwizard/JTier service. Configuration is provided via Dropwizard YAML configuration files (environment-specific) and environment variables injected at runtime. JTier manages datasource connection pooling (PostgreSQL) and HTTP client factory configuration. Specific variable names are not declared in the architecture DSL inventory.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection string for `continuumWolfhoundPostgres` | yes | none | env / vault |
| `DATABASE_USER` | PostgreSQL username | yes | none | env / vault |
| `DATABASE_PASSWORD` | PostgreSQL password | yes | none | vault |
| `RELEVANCE_API_BASE_URL` | Base URL for `continuumRelevanceApi` HTTP client | yes | none | env |
| `DEALS_CLUSTER_BASE_URL` | Base URL for `continuumDealsClusterService` HTTP client | yes | none | env |
| `LPAPI_BASE_URL` | Base URL for `continuumLpapiService` HTTP client | yes | none | env |
| `CONSUMER_AUTHORITY_BASE_URL` | Base URL for `continuumConsumerAuthorityService` HTTP client | yes | none | env |
| `TAXONOMY_SERVICE_BASE_URL` | Base URL for `continuumTaxonomyService` HTTP client | yes | none | env |
| `EXPY_SERVICE_BASE_URL` | Base URL for `continuumExpyService` HTTP client | yes | none | env |
| `SFMC_ENDPOINT` | Salesforce Marketing Cloud submission endpoint | yes | none | env / vault |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here. Actual variable names should be confirmed from the wolfhound-api source repository configuration files.

> The above variables are inferred from the service's declared integrations. Exact names must be verified against the source repository.

## Feature Flags

> No evidence found. Feature flag configuration is not declared in the architecture inventory. Experiment evaluation is delegated to `continuumExpyService` at runtime.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | yaml | Dropwizard application configuration (server, logging, database, HTTP clients) |
| `config-staging.yml` | yaml | Staging environment overrides |
| `config-production.yml` | yaml | Production environment overrides |

> Config file paths are inferred from Dropwizard conventions. Actual paths should be confirmed from the source repository.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_PASSWORD` | PostgreSQL authentication credential | vault |
| `SFMC_API_KEY` | Salesforce Marketing Cloud API authentication | vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Dropwizard supports environment-specific YAML configuration files. Database connection pool sizes, external service base URLs, and HTTP client timeouts are expected to differ between development, staging, and production. JTier's managed datasource and Retrofit factory components apply environment-specific configuration via the active config file at startup.
