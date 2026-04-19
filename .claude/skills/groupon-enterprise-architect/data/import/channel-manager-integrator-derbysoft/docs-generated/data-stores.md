---
service: "channel-manager-integrator-derbysoft"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumChannelManagerIntegratorDerbysoftDb"
    type: "postgresql"
    purpose: "Persists reservation, cancellation, ARI request/response, and external mapping data"
---

# Data Stores

## Overview

The service owns a single PostgreSQL database (`continuumChannelManagerIntegratorDerbysoftDb`) that holds all operational state: reservation lifecycle records, cancellation records, ARI request and response payloads, and hotel/room-type/rate-plan mapping data. Schema migrations are managed via the `jtier-migrations` bundle (Flyway/Liquibase). There are no caches in use.

## Stores

### Channel Manager Integrator Derbysoft DB (`continuumChannelManagerIntegratorDerbysoftDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumChannelManagerIntegratorDerbysoftDb` |
| Purpose | Persists all operational data: reservations, cancellations, ARI payloads, and Derbysoft resource mappings |
| Ownership | owned |
| Migrations path | Managed via `jtier-migrations` (PostgresMigrationBundle); migration files bundled in the application JAR |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Reservation | Tracks the lifecycle of a booking attempt (state machine) | reservation ID, state (RESERVATION_INIT, PRE_BOOK_SUCCEED, PRE_BOOK_FAILED, BOOK_SUCCEED, BOOK_FAILED), hotel UUID |
| ReservationRequest | Stores the outbound prebook/book request payload sent to Derbysoft | reservation ID, request JSON, Derbysoft hotel ID |
| ReservationResponse | Stores the response received from Derbysoft for prebook/book calls | reservation ID, response JSON, success/failure indicator |
| ReservationStateLog | Audit log of all state transitions for a reservation | reservation ID, from-state, to-state, timestamp |
| CancellationRequest | Stores the cancellation request payload sent to Derbysoft | cancellation ID, reservation ID, request JSON |
| CancellationResponse | Stores the Derbysoft cancellation response | cancellation ID, response JSON, success/failure indicator |
| AriRequest | Persists the raw inbound ARI push request payload from Derbysoft | hotel ID, date range, request body JSON, received timestamp |
| AriResponse | Persists the ARI processing response returned to the caller | request ID, response status, response body JSON |
| Hotel | Internal record of Derbysoft hotel identifiers mapped to Groupon hotel UUIDs | hotel UUID, Derbysoft hotel ID, supplier ID |
| RoomType | Maps Derbysoft room-type codes to internal Groupon product identifiers | hotel ID, external room-type code, internal room-type ID |
| RatePlan | Maps Derbysoft rate-plan codes to internal Groupon rate identifiers | hotel ID, external rate-plan code, internal rate-plan ID |
| ExternalHierarchyMapping | Stores the Derbysoft extranet connectivity mapping (hotel, room-type, rate-plan) | hotel UUID, Derbysoft hotel/room-type/rate-plan codes |
| ExternalHierarchyMappingLog | Audit log of changes to the external hierarchy mapping | mapping ID, change type, timestamp |

#### Access Patterns

- **Read**: Reservation state lookups by reservation ID during booking state machine transitions; hotel/room-type/rate-plan mapping lookups during ARI push processing and reservation request construction; ARI request log queries for monitoring
- **Write**: Insert reservation record on RESERVE message receipt; update reservation state on each prebook/book step; insert ARI request/response records on every ARI push; upsert hotel hierarchy mappings via PUT mapping endpoint
- **Indexes**: Not directly visible in this repo snapshot; standard primary key indexes on all entity IDs expected; hotel UUID and Derbysoft hotel ID are the primary lookup keys

## Caches

> No evidence found in codebase. The service does not use an in-memory, Redis, or Memcached cache layer.

## Data Flows

All write operations flow from the application layer (DAO managers) into PostgreSQL via JDBI3 transactions. The `jtier-migrations` bundle applies schema migrations at startup before the application begins processing requests or messages. There is no CDC, ETL, or replication visible in this repo; the database is accessed exclusively by the single application container.
