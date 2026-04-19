---
service: "payments"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumPaymentsDb"
    type: "mysql"
    purpose: "Primary transactional store for payment authorizations, captures, and transaction records"
---

# Data Stores

## Overview

The Payments Service owns a single MySQL database (`continuumPaymentsDb`) provisioned as Database-as-a-Service (DaaS). This store holds all payment authorization records, capture results, and transaction state. It is tagged PCI, reflecting its role in storing sensitive payment data subject to PCI-DSS compliance requirements. Data from this database is replicated via ETL to both the Enterprise Data Warehouse (EDW) and BigQuery for financial analytics and reporting.

## Stores

### Payments DB (`continuumPaymentsDb`)

| Property | Value |
|----------|-------|
| Type | mysql (DaaS) |
| Architecture ref | `continuumPaymentsDb` |
| Purpose | Primary transactional store for payment authorizations, captures, and transaction records |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `payments` | Core payment record per transaction | payment_id, order_id, amount, currency, status, provider, created_at |
| `authorizations` | Authorization records from PSP responses | auth_id, payment_id, provider_ref, status, authorized_at |
| `captures` | Capture records from PSP responses | capture_id, payment_id, provider_ref, amount, captured_at |
| `transactions` | Financial transaction ledger for payment lifecycle | transaction_id, payment_id, type (auth/capture/refund), amount, timestamp |

> Table names and fields above are inferred from the service's domain (payment processing) and component responsibilities (Payment Repository: "CRUD for payments and transactions"). Actual schema should be verified against the source database migrations.

#### Access Patterns

- **Read**: Point lookups by payment_id and order_id for authorization status checks; read by `payments_repository` component during capture operations to validate prior authorization
- **Write**: Transactional writes during authorization (persisting PSP response) and capture (persisting capture result); written by `payments_api` via `payments_repository` after each gateway interaction
- **Indexes**: > No evidence found in codebase. Expected indexes on payment_id, order_id, and status for primary access patterns.

## Caches

> No evidence found in codebase for cache usage. The Payments Service architecture model does not reference Redis or any caching layer.

## Data Flows

- `continuumOrdersService` calls `continuumPaymentsService` to authorize or capture a payment. The Payments API processes the request, routes it through the Provider Router and Provider Client to the external gateway, then persists the result to `continuumPaymentsDb` via `payments_repository`.
- `continuumPaymentsDb` data is replicated via batch ETL to `edw` (Enterprise Data Warehouse) and `bigQuery` for financial analytics, reconciliation, and reporting.
- No CDC or real-time replication patterns are documented in the architecture model; replication is batch-oriented.
