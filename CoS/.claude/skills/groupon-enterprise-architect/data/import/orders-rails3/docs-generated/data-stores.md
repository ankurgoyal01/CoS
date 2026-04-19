---
service: "orders-rails3"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumOrdersDb"
    type: "mysql"
    purpose: "Primary transactional store for orders, billing, payments, and inventory units"
  - id: "continuumFraudDb"
    type: "mysql"
    purpose: "Fraud-specific data store for fraud review state"
  - id: "continuumOrdersMsgDb"
    type: "mysql"
    purpose: "Persistence for order messages and transactional ledger events"
  - id: "continuumRedis"
    type: "redis"
    purpose: "Resque job queues, distributed locks, and response caching"
  - id: "continuumAnalyticsWarehouse"
    type: "vertica"
    purpose: "Analytics and reporting data sink"
---

# Data Stores

## Overview

orders-rails3 owns three relational databases (MySQL/PostgreSQL), one shared Redis instance, and writes reporting data to a Vertica analytics warehouse. The primary store (`continuumOrdersDb`) holds all transactional order data. A separate fraud database (`continuumFraudDb`) isolates fraud-related state. A messaging database (`continuumOrdersMsgDb`) provides durable storage for Message Bus outbox records before event dispatch. Redis serves double duty as both the Resque job queue backend and a distributed locking mechanism.

## Stores

### Orders DB (`continuumOrdersDb`)

| Property | Value |
|----------|-------|
| Type | mysql / postgresql |
| Architecture ref | `continuumOrdersDb` |
| Purpose | Primary transactional store for orders, billing records, payment records, and inventory units |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `orders` | Core order record | order_id, user_id, status, created_at, total_amount |
| `order_line_items` | Individual items within an order | line_item_id, order_id, deal_id, quantity, unit_price |
| `inventory_units` | Voucher/inventory unit records per line item | unit_id, order_id, line_item_id, status, redeemed_at |
| `payments` | Payment records per order | payment_id, order_id, gateway, amount, currency, status |
| `billing_records` | Stored billing/payment method references | billing_record_id, user_id, payment_method_type, status |
| `transactions` | Financial transaction ledger | transaction_id, order_id, type, amount, created_at |

#### Access Patterns

- **Read**: High-frequency point lookups by order_id and user_id; join queries across orders, line items, and inventory units for state management
- **Write**: Transactional writes for order creation, payment processing, and state transitions; batch writes by Workers for collection and refund operations
- **Indexes**: Indexed on order_id, user_id, status, and created_at for primary access patterns

---

### Fraud DB (`continuumFraudDb`)

| Property | Value |
|----------|-------|
| Type | mysql / postgresql |
| Architecture ref | `continuumFraudDb` |
| Purpose | Fraud-specific data store; read during payment authorization and written during fraud review |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `fraud_reviews` | Fraud review records per order | review_id, order_id, status, decision, reviewed_at |
| `fraud_decisions` | Fraud arbiter decision outcomes | decision_id, order_id, provider, result, timestamp |

#### Access Patterns

- **Read**: Point lookups by order_id during payment authorization flow in `continuumOrdersService`
- **Write**: Written by `continuumOrdersWorkers_fraudAndRiskWorkers` when processing fraud review decisions and Accertify resolutions

---

### Orders Messaging DB (`continuumOrdersMsgDb`)

| Property | Value |
|----------|-------|
| Type | mysql / postgresql |
| Architecture ref | `continuumOrdersMsgDb` |
| Purpose | Outbox / durable store for order messages and transactional ledger events prior to Message Bus dispatch |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `order_messages` | Outbox records for Message Bus events | message_id, event_type, payload, published_at, status |
| `transactional_ledger_events` | Ledger event records awaiting dispatch | event_id, order_id, event_type, amount, dispatched_at |

#### Access Patterns

- **Read**: Polled by `continuumOrdersWorkers_paymentProcessingWorkers` and message publishers to identify pending messages
- **Write**: Written synchronously by `continuumOrdersApi_messageBusPublishers` and Workers as part of order processing

---

### Redis Cache/Queue (`continuumRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumRedis` |
| Purpose | Resque job queues, distributed locks, and response caching |
| Ownership | shared |
| Migrations path | Not applicable |

#### Access Patterns

- **Read**: Dequeued by `continuumOrdersWorkers` Resque processes; lock checks by both Service and Workers
- **Write**: Enqueued by `continuumOrdersService` controllers and `continuumOrdersDaemons`; lock acquisition for critical sections

---

### Analytics Warehouse (`continuumAnalyticsWarehouse`)

| Property | Value |
|----------|-------|
| Type | vertica |
| Architecture ref | `continuumAnalyticsWarehouse` |
| Purpose | Analytics and reporting data sink for order and transaction reporting |
| Ownership | shared |
| Migrations path | Not applicable |

#### Access Patterns

- **Read**: Consumed by analytics and reporting tools (external to this service)
- **Write**: Batch-loaded by `continuumOrdersWorkers_miscDomainWorkers` and domain utility workers via batch export

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumRedis` | redis | Response caching for deal/taxonomy data fetched from downstream services | Per-entry, not documented in architecture model |

## Data Flows

- `continuumOrdersService` writes order state to `continuumOrdersDb` transactionally during order placement and payment authorization.
- `continuumOrdersApi_messageBusPublishers` writes outbox records to `continuumOrdersMsgDb` as part of the same transaction; Workers then publish these to the Message Bus.
- `continuumOrdersWorkers` reads from and writes to `continuumOrdersDb` for all async collection, payment, refund, and inventory workflows.
- `continuumOrdersWorkers_miscDomainWorkers` performs batch exports to `continuumAnalyticsWarehouse` for reporting.
- Fraud data flows from `continuumFraudDb` into the authorization path of `continuumOrdersService` and is updated by `continuumOrdersWorkers_fraudAndRiskWorkers`.
