---
service: "deal-catalog-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files"]
---

# Configuration

## Overview

The Deal Catalog Service is a JTier/Dropwizard application configured through a combination of YAML configuration files (Dropwizard convention), environment variables, and JTier platform configuration. Database connections, Redis settings, MBus producer configuration, and Quartz scheduling parameters are the primary configuration surfaces.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_HOST` | MySQL database host for Deal Catalog DB | Yes | - | env |
| `DB_PORT` | MySQL database port | Yes | 3306 | env |
| `DB_NAME` | Database name | Yes | - | env |
| `DB_USERNAME` | Database connection username | Yes | - | env / vault |
| `DB_PASSWORD` | Database connection password | Yes | - | vault |
| `REDIS_HOST` | Redis host for PWA queueing | Yes | - | env |
| `REDIS_PORT` | Redis port | Yes | 6379 | env |
| `MBUS_BROKER_URL` | Message Bus broker connection URL | Yes | - | env |
| `MBUS_TOPIC_DEAL_LIFECYCLE` | MBus topic for deal lifecycle events | Yes | - | env |
| `QUARTZ_CRON_NODE_PAYLOAD` | Cron expression for Node Payload Fetcher schedule | Yes | - | env |
| `SERVICE_PORT` | HTTP port for the Dropwizard application | No | 8080 | env |
| `ADMIN_PORT` | Admin/health check port for Dropwizard | No | 8081 | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

> No evidence found in codebase. Feature flags may be managed through Groupon's platform feature flag system.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | YAML | Main Dropwizard application configuration (server, database, logging) |
| `quartz.properties` | Properties | Quartz scheduler configuration for Node Payload Fetcher jobs |

> Config file paths are inferred from JTier/Dropwizard conventions. Exact paths require source code access.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Database credentials | MySQL connection authentication for Deal Catalog DB | Vault / platform secrets |
| Redis credentials | Redis authentication (if enabled) | Vault / platform secrets |
| MBus credentials | Message Bus producer authentication | Vault / platform secrets |
| Salesforce integration credentials | Authentication for Salesforce REST integration | Vault / platform secrets |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

> No evidence found in codebase. JTier services at Groupon typically use environment-specific configuration overlays managed through the deployment pipeline, with separate database endpoints, Redis instances, and MBus broker URLs for development, staging, and production environments.
