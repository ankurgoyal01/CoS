---
service: "giftcard_service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "giftcard-mysql"
    type: "mysql"
    purpose: "Legacy credit codes and First Data URL registry"
---

# Data Stores

## Overview

The Giftcard Service owns a MySQL database used for two purposes: storing generated legacy credit codes and caching discovered First Data endpoint URLs. The database is accessed via the `mysql2` adapter through ActiveRecord. Connection configuration (host, name, user, password) is supplied entirely through environment variables. The service is otherwise stateless — gift card redemption state is held by the Orders Service and Voucher Inventory Service, not locally.

## Stores

### Giftcard MySQL Database (`giftcard-mysql`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumGiftcardService` |
| Purpose | Stores legacy credit codes and First Data endpoint URL cache |
| Ownership | owned |
| Migrations path | `db/` (managed via `rake db:migrate`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `legacy_credit_codes` | Stores generated alphanumeric credit codes for promotional campaigns | `credit_code` (10-char), `value_in_minor_unit`, `currency_code`, `expiry_date`, `campaign_name`, `redeeming_user_id` |
| `first_data_registrations` | Stores First Data merchant registration credentials (auth, DID) | `auth`, `did` |
| `first_data_urls` | Caches discovered First Data endpoint URLs with their measured ping latency | `url`, `ping` |

#### Access Patterns

- **Read**: `LegacyCreditCode` reads during code validation to enforce uniqueness; `FirstDataRegistration.find_did` reads DID by auth string during registration; `first_data_urls` read by `FirstData::UrlManagement` to route outbound XML requests.
- **Write**: `LegacyCreditCode` writes during batch creation via `/api/v1/legacy_credit_codes`; `first_data_urls` written by the `ServiceDiscovery` background job (runs hourly) after pinging discovered First Data URLs.
- **Indexes**: `legacy_credit_codes.credit_code` is queried for uniqueness on creation; `first_data_registrations.auth` is queried for DID lookup.

## Caches

> No evidence found in codebase. No Redis or Memcached is configured. The `first_data_urls` table in MySQL serves as a URL cache for First Data endpoints (written by the `ServiceDiscovery` job, TTL controlled by job frequency of 1 hour).

## Data Flows

- The `ServiceDiscovery` background job runs hourly, queries the First Data Datawire discovery endpoint, pings all returned URLs, and writes latency-ranked results to the `first_data_urls` table.
- All gift card redemption state (bucks allocations, voucher redemption status) is stored in external services (Orders and VIS), not in this database.
- Database credentials are injected at runtime via `DB_HOST`, `DB_NAME`, `DB_USER`, and `DB_PASSWORD` environment variables.
