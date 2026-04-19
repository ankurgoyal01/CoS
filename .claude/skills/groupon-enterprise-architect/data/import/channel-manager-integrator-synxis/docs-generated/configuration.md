---
service: "channel-manager-integrator-synxis"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

CMI SynXis follows the standard JTier/Dropwizard configuration pattern, driven by a YAML configuration file with environment-specific overrides provided via environment variables. Database connectivity is managed by the JTier DaaS MySQL integration. Kafka and MBus connectivity is managed by JTier platform libraries. SynXis endpoint configuration and credentials are expected as external secrets or environment-injected values.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `SYNXIS_CRS_ENDPOINT_URL` | Base URL for the SynXis ChannelConnectService SOAP endpoint | yes | None | env / config |
| `SYNXIS_CRS_USERNAME` | Credential for SynXis SOAP authentication | yes | None | vault / env |
| `SYNXIS_CRS_PASSWORD` | Credential for SynXis SOAP authentication | yes | None | vault / env |
| `INVENTORY_SERVICE_BASE_URL` | Base URL for Continuum Travel Inventory Service REST API | yes | None | env / config |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka broker connection string for ARI event publishing | yes | None | env / config |
| `MBUS_CONNECTION_URL` | MBus broker connection string for inbound/outbound messaging | yes | None | env / config |
| `DB_URL` | JDBC connection URL for CMI SynXis MySQL database | yes | None | vault / env |
| `DB_USERNAME` | MySQL database username | yes | None | vault / env |
| `DB_PASSWORD` | MySQL database password | yes | None | vault / env |

> IMPORTANT: Actual secret values are never documented. The variable names and purposes above are inferred from architecture model dependencies. Refer to the service repository and Vault/secrets manager for actual names used in deployment.

## Feature Flags

> No evidence found for feature flag configuration in the architecture model.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` (or environment variant) | YAML | Dropwizard application configuration — server, database, Kafka, MBus, and SynXis endpoint settings |

> Exact config file paths are managed within the service repository and deployment pipeline.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| SynXis CRS credentials | Authenticate SOAP calls to SynXis ChannelConnectService | vault / env |
| MySQL credentials | Database access for CMI SynXis | vault / env |

> Secret values are never documented. Only names and rotation policies.

## Per-Environment Overrides

> Deployment configuration managed externally. Environment-specific values (SynXis endpoint URLs, Kafka/MBus broker addresses, database credentials) are injected at deployment time per the JTier/Continuum platform standard. Refer to the deployment pipeline and environment-specific configuration repositories for per-environment settings.
