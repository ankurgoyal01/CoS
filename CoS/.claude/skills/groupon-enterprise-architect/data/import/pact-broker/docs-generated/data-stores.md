---
service: "pact-broker"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumPactBrokerPostgres"
    type: "postgresql"
    purpose: "Primary and sole data store — persists all contract, verification, pacticipant, version, and webhook state"
---

# Data Stores

## Overview

Pact Broker uses a single PostgreSQL database as its primary and only data store. All broker state — including pact contracts, verification results, pacticipant registrations, version metadata, and webhook configurations — is persisted in this database. The connection is configured entirely through `PACT_BROKER_DATABASE_*` environment variables. There are no caches or secondary stores.

## Stores

### Pact Broker Postgres DB (`continuumPactBrokerPostgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumPactBrokerPostgres` |
| Purpose | Persists all broker domain data: pacticipants, pacts, versions, verification results, webhook configs, and execution state |
| Ownership | owned |
| Migrations path | Managed internally by the upstream pact-foundation/pact-broker application on startup |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `pacticipants` | Registered consumer and provider service identities | `name`, `display_name` |
| `versions` | Consumer and provider version records | `number`, `pacticipant_id`, `created_at` |
| `pacts` / `pact_versions` | Stored contract documents | `consumer_id`, `provider_id`, `sha`, `content` |
| `verification_results` | Provider verification outcomes against pact versions | `pact_version_id`, `success`, `provider_version_id` |
| `webhooks` | Configured outbound webhook definitions | `uuid`, `consumer_id`, `provider_id`, `url`, `events` |
| `triggered_webhooks` | Execution history and state of webhook dispatches | `webhook_id`, `status`, `created_at` |

#### Access Patterns

- **Read**: HTTP API components query pacticipants, versions, pacts, and verification results per request. The `can-i-deploy` endpoint performs join queries across versions and verification results.
- **Write**: Consumer services write pact documents via PUT; provider services write verification results via POST. Webhook dispatcher reads and writes execution state for each triggered webhook.
- **Indexes**: Index configuration is managed by the upstream pact-foundation/pact-broker schema migrations and is not visible in this repository.

#### Connection Configuration

| Variable | Purpose |
|----------|---------|
| `PACT_BROKER_DATABASE_HOST` | Database hostname (staging: `pact_broker-rw-na-staging-pg-db.gds.stable.gcp.groupondev.com`) |
| `PACT_BROKER_DATABASE_NAME` | Database name (staging: `pact_broker_stg`) |
| `PACT_BROKER_DATABASE_USERNAME` | Database user (staging: `pact_broker_stg_dba`) |
| `PACT_BROKER_DATABASE_PASSWORD` | Database password — injected from secrets submodule |

## Caches

> Not applicable. No caching layer (Redis, Memcached, or in-memory cache) is configured. All reads go directly to PostgreSQL.

## Data Flows

All data flows through the single PostgreSQL store:
- The `continuumPactBrokerHttpApi` component reads and writes pacticipant, pact, version, and verification data on every API request.
- The `continuumPactBrokerWebhookDispatcher` reads webhook configuration from the database on each triggering event and writes execution status back after delivery.
- No CDC, ETL, or replication pipelines are configured in this repository.
