---
service: "contract-data-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumContractDataServicePostgresRw"
    type: "postgresql"
    purpose: "Primary read/write store for all contract data"
  - id: "continuumContractDataServicePostgresRo"
    type: "postgresql"
    purpose: "Read-only replica for contract data reads"
---

# Data Stores

## Overview

Contract Data Service owns a PostgreSQL database as its primary data store. The service connects to two endpoints: a read/write primary (`continuumContractDataServicePostgresRw`) and a read-only replica (`continuumContractDataServicePostgresRo`). Schema migrations are managed by Flyway via `jtier-migrations`. A Redis dependency is declared in `pom.xml` via `dropwizard-redis` but no active cache usage was found in the service code.

## Stores

### Contract Data Service DB — Primary (`continuumContractDataServicePostgresRw`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumContractDataServicePostgresRw` |
| Purpose | Primary read/write store for all contract records, terms, parties, and invoicing configuration |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migration` (Flyway convention) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `contract_party` | Stores merchant party records associated with contracts | `contract_party_id`, `id` (external), `id_type` (enum: `ContractPartyIdType`), payment schedule (cadence, days) |
| `contract_term` | Stores contract term records with deduplication hash | `contract_term_id` (UUID), `hash`, `source` (enum: `SourceType`), `payment_term_type`, `pricing_type`, `pricing_format`, `payment_invoicing_config_external_key_id_type` |
| `contract_term_external_id` | External IDs associated with a contract term | `contract_term_id` (FK), `id`, `id_type` (enum: `ExternalIdType`), `is_primary` |
| `contract_term_amount` | Pricing amounts for a contract term | `contract_term_id` (FK), `amount`, `currency_code` (enum: `CurrencyType`), `amount_type` (enum: `AmountType`) |
| `contract_term_adjustment` | Payment adjustments on a contract term | `contract_term_id` (FK), `type` (enum: `AdjustmentType`), `amount`, `currency_code`, `percentage` |
| `contract_term_event_action` | Event-driven payment actions | `contract_term_id` (FK), `on_event` (enum: `EventType`), `action_type` (enum: `ActionType`) |
| `payment_invoicing_configuration` | Invoicing config record keyed by external reference | `external_reference_id`, `initial_payment_type` (enum: `EventInitialPaymentType`) |
| `payment_invoicing_configuration_installment` | Installment schedule for invoicing configs | `payment_invoicing_configuration_id` (FK), `type` (enum: `EventInstallmentType`), offset days |
| `client_id` | Authorized client IDs for request filter validation | `client_id` |

#### Access Patterns

- **Read**: Contract terms are read by hash (deduplication check) and by UUID. Contract parties are read by `contractPartyId`. Payment invoicing configurations are read by `externalReferenceId`. The read-only DAO (`continuumContractDataServicePostgresRo`) is used for all read paths.
- **Write**: Inserts and updates are performed through transactional JDBI DAO methods (`insertInTransaction`, `updateInTransaction`). Contract term inserts are preceded by a hash-based deduplication check on the read replica. The write primary (`continuumContractDataServicePostgresRw`) is used exclusively for mutation.
- **Indexes**: Not directly visible in source; Flyway migration scripts at `src/main/resources/db/migration` would contain index definitions.

### Contract Data Service DB — Read Replica (`continuumContractDataServicePostgresRo`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumContractDataServicePostgresRo` |
| Purpose | Read-only replica; serves all GET endpoints and pre-write deduplication lookups |
| Ownership | owned |
| Migrations path | N/A (replica follows primary) |

#### Access Patterns

- **Read**: All GET endpoint DAOs (`ContractTermReadOnlyDao`, `ContractPartyReadOnlyDao`, `PaymentInvoicingConfigurationReadOnlyDao`, `ClientIdReadOnlyDao`) target this replica.
- **Write**: Not applicable — read-only.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Redis | redis | Declared via `dropwizard-redis` dependency | Not configured in source |

> No active Redis cache usage was found in the service source code. The dependency may be inherited from the JTier platform or reserved for future use.

## Data Flows

All data flows are synchronous and request-driven:

1. Writes arrive via REST API — the service validates the payload, performs a deduplication lookup on the read replica, then writes to the primary if needed.
2. Backfill operations pull data from DMAPI and Deal Catalog over HTTP, transform it into CoDS contract format, then write back to DMAPI (via `PUT /v2/deals/{id}`) and return a result summary — CoDS itself does not persist backfill results directly; the CoDS contract creation during backfill goes through `POST /v2/contract_data_service/contract` on DMAPI.
3. No CDC, ETL pipelines, or materialized views were identified.
