---
service: "channel-manager-integrator-synxis"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumChannelManagerIntegratorSynxisDatabase"
    type: "mysql"
    purpose: "Stores mapping configuration, reservation state, request/response logs, and operational metadata"
---

# Data Stores

## Overview

CMI SynXis owns a single MySQL database that serves as the system of record for hotel-to-internal mapping configuration, reservation lifecycle state, and a full audit log of SOAP request/response pairs with SynXis. Access is exclusively through the `mappingPersistence` DAO component using JDBI3, provisioned via the JTier DaaS MySQL integration.

## Stores

### Channel Manager Integrator SynXis Database (`continuumChannelManagerIntegratorSynxisDatabase`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `continuumChannelManagerIntegratorSynxisDatabase` |
| Purpose | Stores mapping configuration, reservation state, SOAP request/response logs, and operational metadata |
| Ownership | owned |
| Migrations path | > No evidence found in architecture model; refer to service repository |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Mapping records | Map external SynXis hotel/room identifiers to internal Continuum identifiers | External hotel ID, internal property ID, external room type, internal room type |
| Reservation records | Track reservation lifecycle (created, confirmed, cancelled) per booking | Reservation ID, SynXis confirmation number, status, timestamps |
| Request/response logs | Audit log of all SOAP operations exchanged with SynXis | Operation type, raw request payload, raw response payload, timestamp, correlation ID |
| Comments / metadata | Operational annotations and supplementary data associated with reservations or mappings | Record ID, comment text, author, timestamp |

#### Access Patterns

- **Read**: `mappingPersistence` reads mapping records during ARI validation (called by `soapAriIngress`) and reads reservation/mapping data during reservation workflows (called by `reservationCancellationService`). `restMappingApi` reads mapping and reservation data for operational queries.
- **Write**: `soapAriIngress` writes ARI request/response logs after each SOAP push operation. `reservationCancellationService` writes reservation state transitions. `restMappingApi` writes mapping updates via `PUT /mapping`.
- **Indexes**: > No evidence found in architecture model; refer to service repository schema.

## Caches

> Not applicable. No caching layer is present in the architecture model.

## Data Flows

MySQL is the only persistent store. Data flows into the database from two directions: (1) SOAP ARI push requests logged by `soapAriIngress`, and (2) reservation/cancellation workflows persisted by `reservationCancellationService`. No CDC, ETL, or replication patterns are evidenced in the architecture model; data is written synchronously at transaction time.
