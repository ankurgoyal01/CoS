---
service: "clo-service"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

CLO Service uses Message Bus (`messageBus`) for all asynchronous event communication. The `continuumCloServiceApi` publishes domain events via the `cloApiEventPublisher` component after claim and enrollment state changes. The `continuumCloServiceWorker` both consumes inbound events from upstream services (via `cloWorkerMessageConsumers`) and publishes follow-up events after async job processing. The service is a significant participant in the Continuum event mesh, handling financial, lifecycle, and inventory event flows.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `clo.claims` | Claim event | Qualifying purchase matched to enrolled offer | claim id, user id, offer id, amount, status |
| `clo.enrollments` | Enrollment event | Card enrolled to or unenrolled from a CLO offer | enrollment id, user id, card token, offer id, status |
| `InventoryUnits.Updated.Clo` | Inventory unit updated | CLO inventory unit state change | inventory unit id, offer id, status, updated fields |
| `InventoryUnits.Created.Clo` | Inventory unit created | New CLO inventory unit registered | inventory unit id, offer id, status |
| `Products.Updated.Clo` | Product updated | CLO product record updated | product id, offer id, updated fields |
| `Products.Created.Clo` | Product created | New CLO product registered | product id, offer id |

### clo.claims Detail

- **Topic**: `clo.claims`
- **Trigger**: A qualifying card transaction is matched to an enrolled CLO offer and a claim is created or updated
- **Payload**: claim id, user id, offer id, merchant id, transaction amount, claim status, timestamp
- **Consumers**: Orders Service, downstream financial and reporting consumers (tracked in central architecture model)
- **Guarantees**: at-least-once

### clo.enrollments Detail

- **Topic**: `clo.enrollments`
- **Trigger**: A user enrolls or unenrolls a payment card in a CLO offer
- **Payload**: enrollment id, user id, card network token, offer id, enrollment status, timestamp
- **Consumers**: Users Service, downstream notification consumers (tracked in central architecture model)
- **Guarantees**: at-least-once

### InventoryUnits.Updated.Clo / InventoryUnits.Created.Clo Detail

- **Topic**: `InventoryUnits.Updated.Clo`, `InventoryUnits.Created.Clo`
- **Trigger**: CLO inventory unit state changes as a result of offer lifecycle events
- **Payload**: inventory unit id, offer id, status, relevant updated fields
- **Consumers**: CLO Inventory Service (`continuumCloInventoryService`), Third-Party Inventory Service (`continuumThirdPartyInventoryService`)
- **Guarantees**: at-least-once

### Products.Updated.Clo / Products.Created.Clo Detail

- **Topic**: `Products.Updated.Clo`, `Products.Created.Clo`
- **Trigger**: CLO product records are created or updated during offer ingestion or lifecycle management
- **Payload**: product id, offer id, relevant updated fields
- **Consumers**: Deal Catalog Service (`continuumDealCatalogService`) and inventory services
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `BillingRecordUpdate` | Billing record update | `cloWorkerMessageConsumers` | Updates claim payment status; triggers statement credit follow-up |
| `dealDistribution` | Deal distribution update | `cloWorkerMessageConsumers` | Syncs CLO offer state with deal catalog changes |
| `FileTransfer` | File transfer notification | `cloWorkerMessageConsumers` | Triggers card network file-based settlement processing |
| `CloInventoryUnits.StatusChanged` | Inventory unit status change | `cloWorkerMessageConsumers` | Updates local CLO inventory unit state |
| `users.account` | User account event | `cloWorkerMessageConsumers` | Creates or updates user CLO profile; triggers enrollment actions |
| `gdpr.erasure` | GDPR erasure request | `cloWorkerMessageConsumers` | Triggers user data anonymization and enrollment removal |
| `dealSnapshot` | Deal snapshot | `cloWorkerMessageConsumers` | Refreshes local deal data for offer matching |
| `salesforce.informationrequest` | Salesforce information request | `cloWorkerMessageConsumers` | Fetches and responds with merchant/offer CRM data |

### BillingRecordUpdate Detail

- **Topic**: `BillingRecordUpdate`
- **Handler**: Message consumer dispatches to async job processor; updates claim billing state and may enqueue statement credit job
- **Idempotency**: Expected; claim state machine (AASM) guards duplicate transitions
- **Error handling**: Sidekiq retry with backoff; failed jobs routed to dead job queue
- **Processing order**: unordered

### dealDistribution Detail

- **Topic**: `dealDistribution`
- **Handler**: `cloWorkerMessageConsumers` dispatches to `cloWorkerAsyncJobs`; syncs offer/deal state with Deal Catalog
- **Idempotency**: Expected; offer state reconciliation is idempotent
- **Error handling**: Sidekiq retry
- **Processing order**: unordered

### gdpr.erasure Detail

- **Topic**: `gdpr.erasure`
- **Handler**: `cloWorkerMessageConsumers` triggers user data erasure job; removes or anonymizes enrollment and claim records for the specified user
- **Idempotency**: Expected; erasure is idempotent
- **Error handling**: Sidekiq retry; critical SOX/compliance path — failures are monitored
- **Processing order**: unordered

### users.account Detail

- **Topic**: `users.account`
- **Handler**: `cloWorkerMessageConsumers` processes account creation, update, and suspension events; adjusts CLO enrollment eligibility accordingly
- **Idempotency**: Expected; account state reconciliation is idempotent
- **Error handling**: Sidekiq retry
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in the architecture inventory for named DLQ configurations. Sidekiq's built-in dead job queue handles permanently failed jobs.
