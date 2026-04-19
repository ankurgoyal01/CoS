---
service: "Deal-Estate"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Deal-Estate participates in Groupon's internal message bus (`messagebus` gem v0.2.15) both as a publisher and as a consumer. It publishes deal option lifecycle events and consumes deal state changes from Deal Catalog, plus merchant/opportunity/pricing data changes from Salesforce, and taxonomy content updates. Background processing of consumed events is handled by `continuumDealEstateWorker`.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `dealEstate.option.create` | option create | New deal option created | option ID, deal ID, option attributes |
| `option.import.status` | import status | Deal import job completes | deal ID, import status, error details |

### dealEstate.option.create Detail

- **Topic**: `dealEstate.option.create`
- **Trigger**: A new deal option is successfully created via the `/deals` API or an import flow
- **Payload**: Includes option ID, parent deal ID, and core option attributes
- **Consumers**: Known downstream consumers tracked in the central architecture model
- **Guarantees**: at-least-once

### option.import.status Detail

- **Topic**: `option.import.status`
- **Trigger**: An import job completes (success or failure) for a deal
- **Payload**: Includes deal ID, resulting import status, and any error details
- **Consumers**: Known downstream consumers tracked in the central architecture model
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `dealCatalog.deals.v1.update` | deal update | Worker: deal catalog sync handler | Updates local deal record from catalog |
| `dealCatalog.deals.v1.paused` | deal paused | Worker: deal state sync handler | Marks deal as paused in Deal-Estate |
| `dealCatalog.deals.v1.unpaused` | deal unpaused | Worker: deal state sync handler | Marks deal as unpaused in Deal-Estate |
| `dealCatalog.deals.v1.published` | deal published | Worker: deal state sync handler | Marks deal as published in Deal-Estate |
| `dealCatalog.deals.v1.unpublished` | deal unpublished | Worker: deal state sync handler | Marks deal as unpublished in Deal-Estate |
| `dealCatalog.deals.v1.distribution` | distribution change | Worker: distribution sync handler | Updates distribution windows for deal |
| `salesforce.opportunity.*` | opportunity events | Worker: Salesforce opportunity sync handler | Syncs opportunity data onto deal records |
| `salesforce.account.*` | account events | Worker: Salesforce account sync handler | Syncs merchant account data onto deal records |
| `salesforce.planning_object.*` | planning object events | Worker: Salesforce planning sync handler | Syncs planning objects onto deal records |
| `salesforce.price.*` | price events | Worker: Salesforce price sync handler | Syncs pricing data onto deal records |
| `salesforce.option.*` | option events | Worker: Salesforce option sync handler | Syncs Salesforce option data onto deal records |
| `taxonomyV2.content.update` | taxonomy update | Worker: taxonomy refresh handler | Refreshes taxonomy classification data on deals |

### dealCatalog.deals.v1.* Detail

- **Topic**: `dealCatalog.deals.v1.*` (update, paused, unpaused, published, unpublished, distribution)
- **Handler**: `continuumDealEstateWorker` — deal catalog state sync workers
- **Idempotency**: Expected idempotent via state_machine guards; duplicate events result in no-op if state already matches
- **Error handling**: Resque retry with backoff; failed jobs visible in `continuumDealEstateResqueWeb`
- **Processing order**: unordered per deal

### salesforce.* Detail

- **Topic**: `salesforce.opportunity.*`, `salesforce.account.*`, `salesforce.planning_object.*`, `salesforce.price.*`, `salesforce.option.*`
- **Handler**: `continuumDealEstateWorker` — Salesforce data sync workers
- **Idempotency**: Upsert-style writes to MySQL; repeat events overwrite with same data
- **Error handling**: Resque retry with backoff; failed jobs visible in `continuumDealEstateResqueWeb`
- **Processing order**: unordered

### taxonomyV2.content.update Detail

- **Topic**: `taxonomyV2.content.update`
- **Handler**: `continuumDealEstateWorker` — taxonomy refresh handler
- **Idempotency**: Overwrites taxonomy classification; repeat events are safe
- **Error handling**: Resque retry with backoff
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found for explicitly configured dead letter queues. Failed Resque jobs are retained in the failed queue visible via `continuumDealEstateResqueWeb` and can be retried manually.
