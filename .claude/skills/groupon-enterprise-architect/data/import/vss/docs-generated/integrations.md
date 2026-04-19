---
service: "vss"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 4
---

# Integrations

## Overview

VSS has four internal Continuum platform dependencies: the Users Service (HTTP), Voucher Inventory Service / VIS (HTTP), VIS 2.0 (HTTP), and the JMS message bus (mbus) for event consumption. All HTTP clients are built with Retrofit2 via the JTier `jtier-retrofit` library. There are no external (third-party) dependencies beyond the Groupon platform infrastructure.

## External Dependencies

> No evidence found in codebase. VSS has no third-party external system integrations.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Users Service | HTTP/REST | Fetch user account details (name, email) by account ID during backfill and enrichment | `continuumUsersService` |
| Voucher Inventory Service (VIS v1) | HTTP/REST | Fetch voucher unit inventory data during backfill | `continuumVoucherInventoryService` |
| VIS 2.0 | HTTP/REST | Fetch voucher unit inventory data from the v2 inventory source during backfill | `visInventory` (stub in local model) |
| Message Bus (mbus) | JMS | Consume voucher inventory update events and user lifecycle events | `mbus` (stub in local model) |

### Users Service Detail

- **Protocol**: HTTP/REST
- **Base URL / SDK**: Configured via `serviceClients.userServiceClient` (Retrofit2 `RetrofitConfiguration`); production base URL `http://users-service.snc1` (managed by JTier service discovery)
- **Auth**: `x-request-id` header forwarded for tracing; no additional auth from VSS side
- **Purpose**: Fetches user name and email data for purchaser and consumer account IDs encountered during backfill operations; endpoint `GET /users/v1/accounts?id={userId}`
- **Failure mode**: If Users Service is unavailable, backfill enrichment fails for affected units; JMS-driven updates continue independently
- **Circuit breaker**: Not explicitly configured in repository; JTier Retrofit client may apply default timeouts

### Voucher Inventory Service (VIS v1) Detail

- **Protocol**: HTTP/REST
- **Base URL / SDK**: Configured via `serviceClients.visClient` (Retrofit2 `RetrofitConfiguration`)
- **Auth**: No explicit auth in client configuration visible from source
- **Purpose**: Fetches inventory unit details (UUID, `updatedAt`, merchant context) during backfill scheduler runs
- **Failure mode**: Backfill run for affected unit range fails; subsequent scheduler execution retries
- **Circuit breaker**: Not explicitly configured

### VIS 2.0 Detail

- **Protocol**: HTTP/REST
- **Base URL / SDK**: Configured via `serviceClients.visV2Client` (Retrofit2 `RetrofitConfiguration`)
- **Auth**: No explicit auth in client configuration visible from source
- **Purpose**: Fetches voucher inventory units from the VIS 2.0 source (identified by `inventoryServiceId=vis`)
- **Failure mode**: Same as VIS v1; backfill for this source range retried on next scheduler run
- **Circuit breaker**: Not explicitly configured

### Message Bus (mbus) Detail

- **Protocol**: JMS (ActiveMQ-backed mbus platform)
- **Base URL / SDK**: Configured via `messageBus` block in `VssConfiguration`; `jtier-messagebus-client` library
- **Auth**: Platform-managed
- **Purpose**: Receives inventory unit update events (two topics) and user lifecycle events (three topics); drives real-time data sync into VSS MySQL
- **Failure mode**: Message processing errors tracked and alerted via Wavefront; failed messages may be retried per mbus platform guarantees
- **Circuit breaker**: Not applicable — consumer model; mbus platform handles delivery guarantees

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `merchantCenter` | HTTP/REST | Calls `GET /v1/vouchers/search` and `POST /v1/vouchers/search` to power the voucher search UI in Merchant Centre |

> Upstream consumers are tracked in the central architecture model under `merchantCenter -> continuumVssService`.

## Dependency Health

- Users Service, VIS v1, and VIS 2.0 health is monitored indirectly via backfill job success rates and JMS processing error counts in Wavefront.
- JMS message bus subscription health is monitored via mbus dashboard links documented in `doc/owners_manual.md`.
- Alert "VSS JMS Msg processor Errors" fires on Wavefront if `userUpdateErrorCount` exceeds WARN (5) or SEVERE (10) thresholds.
- Alert "VSS JMS Msg processor Failure" fires if `jmsUserFailCount` or `jmsUnitFailCount` exceeds WARN (1) or SEVERE (100) thresholds.
