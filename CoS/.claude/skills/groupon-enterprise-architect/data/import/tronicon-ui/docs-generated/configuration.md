---
service: "tronicon-ui"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, dotenv]
---

# Configuration

## Overview

Tronicon UI is configured through a combination of a `.env` file (loaded at startup via python-dotenv), static JSON config files in the `gconfig/` directory, and a deployment configuration file (`deploy-config.js`). Database credentials, API credentials, and OAuth2 credentials are supplied as environment variables. The `alembic/` directory manages database schema migration configuration. No external configuration service (Consul, Vault, Kubernetes secrets) is confirmed active.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_HOST` | MySQL database host | yes | none | .env |
| `DB_PORT` | MySQL database port | yes | none | .env |
| `DB_NAME` | MySQL database name | yes | none | .env |
| `DB_USER` | MySQL database username | yes | none | .env |
| `DB_PASSWORD` | MySQL database password | yes | none | .env |
| `GROUPON_API_BASE_URL` | Base URL for Groupon public API (`continuumGrouponApi`) | yes | none | .env |
| `GROUPON_API_CLIENT_ID` | OAuth2 client ID for Groupon API | yes | none | .env |
| `GROUPON_API_CLIENT_SECRET` | OAuth2 client secret for Groupon API | yes | none | .env |
| `ALLIGATOR_SERVICE_URL` | Base URL for Alligator experiments service (`continuumAlligatorService`) | yes | none | .env |
| `TAXONOMY_SERVICE_URL` | Base URL for Taxonomy Service (`continuumTaxonomyService`) | yes | none | .env |
| `CAMPAIGN_SERVICE_URL` | Base URL for Campaign Service proxy target (`campaignService`) | yes | none | .env |
| `CELERY_BROKER_URL` | Broker URL for Celery async task queue | yes | none | .env |
| `SECRET_KEY` | Application session secret key | yes | none | .env |
| `ENVIRONMENT` | Runtime environment name (development, staging, production) | yes | none | .env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase for a dedicated feature flag system. A/B testing is delegated to the Alligator Service (`continuumAlligatorService`) and Birdcage Experiments (`birdcageExperiments`).

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.env` | dotenv key=value | Primary runtime environment variable source loaded by python-dotenv at startup |
| `gconfig/cardatron.json` | JSON | Cardatron card property configuration — defines card field definitions and display properties |
| `alembic/alembic.ini` | INI | Alembic migration runner configuration, including database connection string for migrations |
| `alembic/env.py` | Python | Alembic migration environment setup; references SQLAlchemy models |
| `deploy-config.js` | JavaScript/JSON | Deployment configuration for Fabric/Jenkins CI pipeline — environment targets, hostnames, deploy parameters |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_PASSWORD` | MySQL database password | .env file (environment-injected at deploy time) |
| `GROUPON_API_CLIENT_SECRET` | OAuth2 client secret for Groupon API authentication | .env file (environment-injected at deploy time) |
| `SECRET_KEY` | Application session signing secret | .env file (environment-injected at deploy time) |

> Secret values are NEVER documented. Only names and rotation policies are noted here. Rotation procedures are managed by the Tronicon / Sparta team.

## Per-Environment Overrides

Configuration is differentiated by environment through separate `.env` file variants injected at deploy time by the Fabric + Jenkins CI/CD pipeline. The `ENVIRONMENT` variable controls runtime behavior switches. The `deploy-config.js` file defines environment-specific deployment targets (development, staging, production). No Kubernetes config maps or Helm values files are present — environment separation is handled entirely through the deployment pipeline injecting environment-specific `.env` content.
