---
service: "deletion_service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumDeletionServiceDb"
    type: "postgresql"
    purpose: "Stores erase requests, per-service erasure state, and SMS consent send IDs"
  - id: "ordersMySql"
    type: "mysql"
    purpose: "Read-only for fulfillment lookup; write target for order data anonymisation"
---

# Data Stores

## Overview

The Deletion Service owns one primary PostgreSQL database (Deletion Service DB) which it uses to track all erasure requests and their per-service execution status. It also connects to the Orders MySQL database (owned by the Orders service) in order to read fulfillment line items and anonymise customer order data. No caching layer is employed by this service.

## Stores

### Deletion Service DB (`continuumDeletionServiceDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumDeletionServiceDb` |
| Purpose | Stores erase requests (top-level records), per-service erase tasks, status tracking (started, finished, error details), and SMS consent send IDs |
| Ownership | Owned by this service |
| Migrations path | Managed via JTier `jtier-migrations` (exact migration path not discoverable from source; JTier convention is `src/main/resources/db/migrations/`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Erase Request | Tracks one erasure request per customer, created when an erase event is received | `id`, `customerId`, `createdAt`, `finishedAt`, `erasedAt`, `publishedAt`, `retryCount` |
| Erase Service | Tracks erasure status for each downstream service per request | `id`, `requestId`, `name` (EraseServiceType), `startedAt`, `finishedAt`, `errorCode`, `errorMessage` |
| SMS Consent Send | Records the Rocketman `sendId` returned when an Attentive SMS consent deletion email is sent | `consumerId`, `sendId` |

#### Access Patterns

- **Read**: Queries unfinished erase requests up to a configurable `eraseRequestMaxRetries` limit (default: 3) for the Quartz scheduler job; queries per-service unfinished tasks for a given request; checks whether a customer has already been basted (via `RetrieveCustomerService`).
- **Write**: Inserts new erase request records and per-service task records when an erase event arrives; updates `startedAt`, `finishedAt`, error codes, and retry counts as each service task progresses; records completion timestamps on successful full erasure.
- **Indexes**: Not directly visible from source; expected indexes on `customerId` and `finishedAt` for efficient pending-request queries.

### Orders MySQL (`ordersMySql`)

| Property | Value |
|----------|-------|
| Type | MySQL |
| Architecture ref | `ordersMySql` (unresolved external in DSL — owned by the Orders service) |
| Purpose | Source of fulfillment line item data; write target for anonymising customer PII in order records |
| Ownership | Shared (owned by the Orders service; accessed by Deletion Service for GDPR erasure) |
| Migrations path | Not applicable — migrations managed by the Orders service |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Fulfillment Line Item | Stores per-order fulfillment details containing customer PII | `customerId`, `fulfillmentId`, and customer PII fields |

#### Access Patterns

- **Read**: `OrdersQuery.getFulfillmentIdList(customerId)` retrieves all fulfillment IDs for a customer; `OrdersQuery.getFulfillmentLineItemList(customerId)` retrieves full line items used to gate erasure (erasure skipped if no orders found).
- **Write**: `OrdersQuery.updateFulfillments(fulfillmentIds)` anonymises customer PII across all fulfillment records for a given customer.
- **Indexes**: Not discoverable from this service's source.

## Caches

> No caching configured. The OWNERS_MANUAL explicitly states: "This service does not employ any sort of caching mechanism."

## Data Flows

1. An `EraseMessage` arrives on the MBUS topic and is consumed by the Erase Message Worker.
2. `CreateCustomerService` writes a new erase request row to `continuumDeletionServiceDb` along with per-service task rows for each enabled `EraseServiceType` mapped to the request's region and option.
3. The Quartz scheduler queries `continuumDeletionServiceDb` for unfinished requests and, for each, loads pending service tasks.
4. For `ORDERS` service tasks, `EraseRequestAction` reads from Orders MySQL to identify fulfillment IDs, then writes anonymised values back to Orders MySQL.
5. On completion of each service task, `continuumDeletionServiceDb` is updated with the finish timestamp and a completion event is published to MBUS.
6. On full request completion, the top-level erase request row in `continuumDeletionServiceDb` is marked finished.
