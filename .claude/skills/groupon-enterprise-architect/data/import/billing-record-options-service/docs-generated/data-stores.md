---
service: "billing-record-options-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "daasPostgresPrimary"
    type: "postgresql"
    purpose: "Primary relational store for all payment method configuration data"
  - id: "raasRedis"
    type: "redis"
    purpose: "Low-latency cache for payment method data"
---

# Data Stores

## Overview

BROS owns a PostgreSQL database (managed through the Groupon DaaS platform) that stores all payment method configuration: applications, client types, countries, payment types, payment providers, and provider importance rankings. A Redis cache (managed through the RAAS platform) provides a low-latency read layer. Both stores are deployed regionally in NA and EMEA.

## Stores

### Bros PostgreSQL Database (`daasPostgresPrimary`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `daasPostgresPrimary` |
| Purpose | Primary configuration store for payment method data — applications, client types, countries, payment types, payment providers, and provider importance |
| Ownership | owned (schema `bros`; DB provisioned via DaaS) |
| Migrations path | `src/main/resources/db/migrations/` (executed via `FlywayMigrateCommand` / `jtier-migrations`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `applications` | Registered client applications (FRONTEND, MOBILE, CHECKOUT, ADMIN) | `id`, `name`, `display_name` |
| `client_types` | Client type definitions resolved from user-agent regexes | `type`, `user_agent_regex`, `rank` |
| `applications_client_types` | Many-to-many mapping of applications to supported client types | `application_id`, `client_type` |
| `countries` | Country-level metadata and payment configuration (stored as JSONB) | `country_code`, `data` (JSONB), `active` |
| `payment_types` | Payment type definitions including billing record type, variant, and flow type | `payment_type`, `billing_record_type`, `billing_record_variant`, `flow_type`, `data` (JSONB) |
| `payment_providers` | Payment providers associated with a country and payment type, with include/exclude filter rules | `id`, `name`, `country_iso_code`, `payment_type`, `data` (JSONB), `include_filters` (JSONB), `exclude_filters` (JSONB) |
| `payment_provider_importance` | Client-type-specific importance rankings for payment providers | `client_type`, `payment_provider_id`, `importance` |
| `applications_payment_providers` | Active payment provider assignments per application | `application_id`, `payment_provider_id`, `active` |

#### Access Patterns

- **Read**: All reads flow through the JDBI Data Accessor (`brosJdbiDataAccessor`). The service reads all relevant configuration tables on each request (or from cache). DAO classes — `ApplicationDao`, `ClientTypeDao`, `CountryDao`, `PaymentTypeDao`, `PaymentProviderDao`, `PaymentProviderImportanceDao`, `ApplicationPaymentProviderDao`, `ApplicationClientTypeDao` — cover all entities.
- **Write**: Configuration data is seeded and managed via Flyway migrations and the `FlywayMigrateCommand` CLI. The application layer performs no write operations during normal request handling.
- **Indexes**: Primary keys on all tables; unique constraints on `applications_client_types(application_id, client_type)`, `payment_provider_importance(client_type, payment_provider_id)`, and `applications_payment_providers(application_id, payment_provider_id)`.

#### Database Endpoints (Regional)

| Environment | Region | Role | Host |
|-------------|--------|------|------|
| Staging | NA (us-west-1) | RW | `bros-rw-na-staging-db.gds.stable.gcp.groupondev.com:5432` |
| Staging | NA (us-west-1) | RO | `bros-ro-na-staging-db.gds.stable.gcp.groupondev.com:5432` |
| Staging | EMEA (us-west-2) | RW | `bros-rw-emea-staging-db.gds.stable.gcp.groupondev.com:5432` |
| Staging | EMEA (us-west-2) | RO | `bros-ro-emea-staging-db.gds.stable.gcp.groupondev.com:5432` |
| Production | NA (us-west-1) | RW | `bros-rw-na-production-db.gds.prod.gcp.groupondev.com:5432` |
| Production | NA (us-west-1) | RO | `bros-ro-na-production-db.gds.prod.gcp.groupondev.com:5432` |
| Production | EMEA (eu-west-1) | RW | `bros-rw-emea-production-db.gds.prod.gcp.groupondev.com:5432` |
| Production | EMEA (eu-west-1) | RO | `bros-ro-emea-production-db.gds.prod.gcp.groupondev.com:5432` |

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `raasRedis` | redis | Low-latency cache layer for payment method data (configured via `payment-cache` SDK) | Managed by `ICacheConfig` — specific TTL not discoverable from source |

#### Redis Endpoints (Regional)

| Environment | Region | Host | Port |
|-------------|--------|------|------|
| Staging | NA | `bros-cache--redis.staging` | 6379 |
| Staging | EMEA | `bros-cache--redis.staging` | 6379 |
| Production | NA | `bros-cache--redis.prod` | 6379 |
| Production | EMEA | `bros-cache--redis.prod` | 6379 |

## Data Flows

Configuration data is seeded into PostgreSQL via Flyway migrations and managed by DB administrators. The application reads this data via JDBI DAOs on each request. The Redis cache layer (via `payment-cache` SDK) is populated on cache misses and serves subsequent reads. There is no CDC, ETL, or replication between the `bros` schema and any other system; all data originates and is managed within this service's database.
