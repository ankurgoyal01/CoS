---
service: "global_subscription_service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumSmsConsentPostgres"
    type: "postgresql"
    purpose: "Primary store for SMS consent records, consent types, and phone mappings"
  - id: "continuumPushTokenPostgres"
    type: "postgresql"
    purpose: "Primary store for push device tokens and push subscriptions"
  - id: "continuumPushTokenCassandra"
    type: "cassandra"
    purpose: "Legacy store for push token data (migration to Postgres in progress)"
---

# Data Stores

## Overview

The Global Subscription Service owns three data stores. Two PostgreSQL instances serve as primary stores: one for SMS consent and subscription data, one for push notification token data. A Cassandra cluster provides backward-compatible access to push token data that pre-dates the PostgreSQL migration. Schema migrations are managed via `jtier-migrations` (JTier's Flyway-based migration runner). An embedded PostgreSQL instance (`otj-pg-embedded`) is used for integration testing.

## Stores

### SMS Consent Postgres (`continuumSmsConsentPostgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumSmsConsentPostgres` |
| Purpose | Stores SMS consent records, consent types (taxonomy), phone-to-consumer mappings, and subscription list metadata |
| Ownership | owned |
| Migrations path | Managed by `jtier-migrations` (Flyway); exact directory managed by JTier conventions |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| consent_types | Defines SMS consent taxonomy per country/locale/client | uuid, country_code, locale, client_id, name, description |
| consents | Records per-consumer or per-phone SMS consent state | uuid, consumer_id, phone_id, consent_type_uuid, status, created_at, updated_at |
| phones | Normalised phone number registry | uuid, e164_phone_number, country_code |
| subscription_lists | Email/SMS subscription list definitions per country | uuid, country_code, list_type, list_id, visible |

#### Access Patterns

- **Read**: Consent lookup by consumer UUID + country/locale; consent type lookup by client_id; phone number lookup for unsubscribe
- **Write**: Consent insert on opt-in; consent status update on opt-out or update; phone upsert on new number
- **Indexes**: Consumer UUID and phone UUID are used as primary lookup keys; country_code + locale are secondary query dimensions

---

### Push Token Postgres (`continuumPushTokenPostgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumPushTokenPostgres` |
| Purpose | Stores push device tokens and push subscription records as the primary (post-migration) store |
| Ownership | owned |
| Migrations path | Managed by `jtier-migrations`; `ptsPostgres` config key (`PtsPostgresConfiguration`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| push_device_tokens | Stores registered push tokens per device/consumer | device_token, consumer_id, app_type, country_code, status, created_at, updated_at |
| push_subscriptions | Records push subscription assignments per token | public_id, device_token, division_uuid, status |

#### Access Patterns

- **Read**: Token lookup by device token value, device ID, consumer UUID; filtered by status (active / activating / inactive / failed) and app_type
- **Write**: Token insert on registration; token status update on lifecycle change; subscription upsert on push subscription create
- **Indexes**: device_token (primary lookup); consumer_id (consumer-level queries); device_id (device-level queries)

---

### Push Token Cassandra (`continuumPushTokenCassandra`)

| Property | Value |
|----------|-------|
| Type | Cassandra |
| Architecture ref | `continuumPushTokenCassandra` |
| Purpose | Legacy push token store; read/written for backward compatibility during Postgres migration |
| Ownership | owned (shared with legacy push token systems) |
| Migrations path | Not applicable — schema managed externally |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| push_device_tokens (Cassandra) | Legacy push token records pre-dating Postgres migration | device_token (partition key), consumer_id, app_type, status |

#### Access Patterns

- **Read**: Token lookup by device token (partition key) for migration and backward-compatible reads
- **Write**: Legacy writes during transition; post-migration writes disabled once data migration is complete
- **Indexes**: Partition key is device token

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| consentTypeCache | in-memory | Caches consent type lookups by country/locale/client to reduce database round-trips | Configured via `consentTypeCacheConfiguration` map |
| smsTemplateCache | in-memory | Caches SMS message templates | Configured via `smsTemplateCacheConfiguration` map |
| clientDetailsCache | in-memory | Caches client detail records | Configured via `clientDetailsCacheConfiguration` map |

## Data Flows

Push token data is being migrated from Cassandra to PostgreSQL via a MBus-driven data migration flow. The `mbusDataMigrationConfiguration` consumer reads migration events, reads the corresponding record from Cassandra, and upserts it into the Postgres push token store. The migration endpoint `/push-subscription/migration/{token}` and replay endpoints (`/push-token/device-token/{token}/replay/create`, `/push-token/device-token/{token}/replay/update`) support manual backfill and event replay. Once migration is complete, Cassandra reads will be decommissioned.
