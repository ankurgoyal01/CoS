---
service: "vss"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumVssService", "continuumVssMySql"]
---

# Architecture Context

## System Context

VSS sits within the Continuum platform as a supporting service for the Merchant Centre portal. Merchant Centre calls VSS to perform voucher searches on behalf of logged-in merchants. VSS maintains its own MySQL data store populated by consuming JMS events from the message bus (inventory unit updates and user account events) and by periodically backfilling from upstream inventory services (VIS v1 and VIS 2.0). On search, VSS queries its local store and optionally enriches results via the Users Service.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| VSS Service | `continuumVssService` | Service | Java, Dropwizard (JTier) | 2.0.x | Voucher Smart Search API, backfill processing, and message consumption |
| VSS MySQL | `continuumVssMySql` | Database | MySQL (DaaS) | — | Voucher smart search primary data store; master/slave replication |

## Components by Container

### VSS Service (`continuumVssService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `vssResource` | REST API entry point for voucher/user search and admin operations | JAX-RS (Dropwizard) |
| `searchService` | Orchestrates search query execution and result aggregation | Java |
| `voucherUserDataService` | Read/write access layer for voucher-user data | Java |
| `voucherUsersDataDbi` | JDBI DAO — executes SQL against VSS MySQL | JDBI |
| `usersUpdateProcessorHelper` | Shared logic consumed by user update event processors | Java |
| `inventoryUnitsUpdatedProcessor` | Consumes `InventoryUnits.Updated` JMS events from VIS v1 and VIS 2.0 | Java |
| `usersDeletionProcessor` | Processes GDPR user erasure events from `gdpr.account.v1.erased` topic | Java |
| `usersEmailUpdatedProcessor` | Processes user email change events from `users.email_change.v1.completed` | Java |
| `usersUpdatedProcessor` | Processes user account update events from `users.account.v1.updated` | Java |
| `voucherBackfillScheduler` | Quartz-scheduled job to backfill voucher-user data from inventory sources | Quartz |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `merchantCenter` | `continuumVssService` | Searches vouchers and users | HTTP/REST |
| `continuumVssService` | `continuumVssMySql` | Reads/writes voucher user data | MySQL |
| `continuumVssService` | `continuumUsersService` | Fetches user details (`GET /users/v1/accounts`) | HTTP/REST |
| `continuumVssService` | `continuumVoucherInventoryService` | Fetches voucher inventory units | HTTP/REST |
| `continuumVssService` | `mbus` | Consumes inventory/user update events | JMS (Message Bus) |

## Architecture Diagram References

- System context: `contexts-vss`
- Container: `containers-vss`
- Component: `components-vss-searchService-components`
