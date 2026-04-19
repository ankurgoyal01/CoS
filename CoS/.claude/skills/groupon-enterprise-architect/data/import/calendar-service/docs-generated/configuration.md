---
service: "calendar-service"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, jtier-daas]
---

# Configuration

## Overview

Calendar Service is configured through the standard JTier/Dropwizard configuration model. Environment-specific values — database connection strings, Redis coordinates, MBus broker settings, and external service base URLs — are injected as environment variables or managed via JTier DaaS connection provisioning. Dropwizard YAML config files provide structural configuration for the server, connection pools, and Quartz scheduler. Secrets such as database credentials and API keys are managed outside the service repository via the platform secrets store.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL DaaS connection URL for `continuumCalendarPostgres` | yes | none | env / JTier DaaS |
| `MYSQL_DATABASE_URL` | MySQL DaaS connection URL for `continuumCalendarMySql` | yes | none | env / JTier DaaS |
| `REDIS_URL` | Redis connection URL for `continuumCalendarRedis` | yes | none | env / JTier DaaS |
| `MBUS_BROKER_URL` | MBus broker endpoint for `availabilityEngineEventsBus` publish/consume | yes | none | env |
| `EPODS_BASE_URL` | Base URL for the EPODS REST API | yes | none | env |
| `THIRD_PARTY_BOOKING_BASE_URL` | Base URL for the Third-Party Booking Service REST API | yes | none | env |
| `APPOINTMENTS_SERVICE_BASE_URL` | Base URL for the Appointments Service REST API | yes | none | env |
| `M3_PLACE_BASE_URL` | Base URL for the M3 Place Service REST API | yes | none | env |
| `M3_MERCHANT_BASE_URL` | Base URL for the M3 Merchant Service REST API | yes | none | env |
| `VOUCHER_INVENTORY_BASE_URL` | Base URL for the Voucher Inventory Service REST API | yes | none | env |
| `THIRD_PARTY_INVENTORY_BASE_URL` | Base URL for the Third-Party Inventory Service REST API | yes | none | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found. No feature flags are declared in the federated architecture DSL. Consult the service repository and JTier feature flag configuration for active flags.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | YAML | Dropwizard server configuration: HTTP connector, thread pool, logging, database pool, Quartz scheduler settings |
| `config-{env}.yml` | YAML | Per-environment overrides for server bindings, connection pool sizes, and external service URLs |

> Exact file paths are not declared in the architecture DSL. Standard JTier/Dropwizard conventions apply.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `POSTGRES_PASSWORD` | Authentication credential for `continuumCalendarPostgres` | Platform secrets store / JTier DaaS |
| `MYSQL_PASSWORD` | Authentication credential for `continuumCalendarMySql` | Platform secrets store / JTier DaaS |
| `REDIS_PASSWORD` | Authentication credential for `continuumCalendarRedis` | Platform secrets store / JTier DaaS |
| `EPODS_API_KEY` | Authentication token for EPODS API calls | Platform secrets store |
| `MBUS_CREDENTIALS` | Authentication credentials for MBus broker connection | Platform secrets store |

> Secret values are NEVER documented. Only names and rotation policies are listed here.

## Per-Environment Overrides

- **Development**: Local database and Redis instances; MBus broker pointed at a local or shared dev broker; external service URLs pointed at sandbox/staging endpoints
- **Staging**: JTier DaaS-provisioned Postgres and MySQL instances; Redis cluster; MBus broker on staging bus; external services on staging URLs
- **Production**: JTier DaaS-provisioned production Postgres and MySQL instances; production Redis cluster; MBus production broker; all external service URLs pointed at production endpoints; larger connection pool sizes and Quartz thread pool configured for production load
