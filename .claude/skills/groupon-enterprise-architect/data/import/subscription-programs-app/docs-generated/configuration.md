---
service: "subscription-programs-app"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

Subscription Programs App is configured via JTier/Dropwizard YAML configuration files, with environment-specific values supplied through environment variables or JTier's configuration injection mechanism. Key configuration areas cover database connectivity, KillBill client credentials, MBus connection settings, external service URLs (Incentive Service, Orders Service, Rocketman, TPIS), and Quartz scheduler parameters for the Worker container.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_URL` | JDBC connection URL for `mm_programs` MySQL database | yes | — | env / config file |
| `DB_USERNAME` | MySQL database username | yes | — | env / vault |
| `DB_PASSWORD` | MySQL database password | yes | — | env / vault |
| `KILLBILL_BASE_URL` | KillBill API base URL | yes | — | env / config file |
| `KILLBILL_USERNAME` | KillBill API username | yes | — | env / vault |
| `KILLBILL_PASSWORD` | KillBill API password | yes | — | env / vault |
| `KILLBILL_API_KEY` | KillBill tenant API key | yes | — | env / vault |
| `KILLBILL_API_SECRET` | KillBill tenant API secret | yes | — | env / vault |
| `MBUS_BROKER_URL` | MBus broker connection URL for `jms.topic.select.MembershipUpdate` publishing | yes | — | env / config file |
| `INCENTIVE_SERVICE_URL` | Base URL for Incentive Service calls | yes | — | env / config file |
| `ORDERS_SERVICE_URL` | Base URL for Orders Service calls | yes | — | env / config file |
| `ROCKETMAN_URL` | Base URL for Rocketman email service | yes | — | env / config file |
| `TPIS_URL` | Base URL for TPIS (optional third-party incentive service) | no | — | env / config file |
| `TPIS_ENABLED` | Feature flag to enable/disable TPIS integration | no | false | env / config file |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `TPIS_ENABLED` | Enables/disables optional TPIS third-party incentive integration | false | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | YAML | Dropwizard/JTier application configuration — database, server, MBus, external service URLs, Quartz scheduler |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_PASSWORD` | MySQL `mm_programs` database password | vault / env |
| `KILLBILL_PASSWORD` | KillBill API user password | vault / env |
| `KILLBILL_API_KEY` | KillBill tenant API key | vault / env |
| `KILLBILL_API_SECRET` | KillBill tenant API secret | vault / env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

JTier service configuration follows Continuum conventions: environment-specific YAML overlays or environment variable injection are used to switch database hostnames, KillBill endpoints, and MBus broker URLs between development, staging, and production. The Quartz scheduler job intervals are typically reduced in non-production environments to accelerate testing cycles.
