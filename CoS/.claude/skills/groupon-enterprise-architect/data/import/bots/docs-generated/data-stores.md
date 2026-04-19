---
service: "bots"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumBotsMysql"
    type: "mysql"
    purpose: "Primary relational datastore for all booking, merchant, campaign, service, availability, voucher, and calendar sync records"
---

# Data Stores

## Overview

BOTS owns a single primary relational data store, `continuumBotsMysql` (MySQL). Both `continuumBotsApi` and `continuumBotsWorker` read and write to this store — the API for real-time booking operations, and the Worker for background job processing and state updates. There is no secondary cache or external analytics store managed directly by BOTS.

## Stores

### BOTS MySQL (`continuumBotsMysql`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumBotsMysql` |
| Purpose | Primary relational datastore containing booking, merchant, calendar sync, voucher, and scheduling records |
| Ownership | owned |
| Migrations path | > Not discovered in repository inventory — contact BOTS team |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `bookings` | Core booking records tracking appointment state and lifecycle | booking ID, merchant ID, service ID, consumer ID, scheduled time, status |
| `merchants` | Merchant configuration and onboarding state within BOTS | merchant ID, onboarding status, calendar sync config |
| `campaigns` | Merchant campaign configuration for bookable deals | campaign ID, merchant ID, deal reference, active status |
| `services` | Merchant service definitions associated with bookable deals | service ID, merchant ID, campaign ID, duration, capacity |
| `availability` | Merchant availability windows and slot definitions | merchant ID, service ID, date, time slots, capacity |
| `vouchers` | Voucher redemption tracking and state | voucher ID, booking ID, merchant ID, redemption status |
| `calendar` | Google Calendar sync state and event mappings | merchant ID, google calendar ID, sync token, last sync time |

#### Access Patterns

- **Read**: The API reads booking state, availability windows, merchant config, and voucher details on every inbound request. The Worker reads pending jobs and booking state during scheduled processing.
- **Write**: The API writes new bookings, status transitions (confirm, cancel, reschedule, checkin), and availability updates. The Worker writes job completion state, voucher redemption outcomes, and GDPR erasure results.
- **Indexes**: Specific index definitions are not visible in this inventory. Expected indexes include merchant ID, booking status, and scheduled time for efficient availability and booking queries.

## Caches

> No application-level caches (Redis, Memcached, or in-memory) were identified in the repository inventory. BOTS reads directly from MySQL for all operations.

## Data Flows

- `continuumBotsApi` writes booking lifecycle state to `continuumBotsMysql`; `continuumBotsWorker` reads and processes that state asynchronously for notifications and job execution.
- GDPR erasure events cause `continuumBotsWorker` to delete or anonymize personal data rows in `continuumBotsMysql`.
- Calendar sync state is written by `continuumBotsWorker` after each Google Calendar import/export cycle.
- Voucher redemption outcomes written by `continuumBotsWorker` after coordinating with `continuumVoucherInventoryService`.
