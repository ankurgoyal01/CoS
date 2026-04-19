---
service: "deal-management-api"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [resque]
---

# Events

## Overview

DMAPI uses Resque (backed by Redis) for internal async job dispatch between the API container and the Worker container. The API enqueues jobs to Redis; the Worker dequeues and processes them. Externally, the service propagates deal state changes to Salesforce and Deal Catalog Service — both synchronously (from the API) and asynchronously (from the Worker). No external message-bus topics (Kafka, RabbitMQ, SQS) were identified in the inventory.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Resque queue (Redis) | `deal_created_async` | POST /v2/deals or /v3/deals (async path) | deal_id, deal attributes, operator context |
| Resque queue (Redis) | `deal_updated` | Deal update operation | deal_id, changed fields, operator context |
| Salesforce sync | `salesforce_deal_sync` | Deal create/update/publish | deal_id, merchant_id, deal state, CRM fields |
| Deal Catalog update | `catalog_update` | Deal publish/unpublish/update | deal_id, catalog payload, effective timestamp |

### `deal_created_async` Detail

- **Topic**: Resque queue backed by `continuumDealManagementRedis`
- **Trigger**: Client POSTs to async deal creation endpoint (v2/v3 async path)
- **Payload**: deal_id, full deal attributes, requesting operator identity
- **Consumers**: `continuumDealManagementWorker` (`resqueWorkers_DeaMan`)
- **Guarantees**: at-least-once (Resque retry semantics)

### `salesforce_deal_sync` Detail

- **Topic**: Salesforce REST API (outbound call from Worker)
- **Trigger**: Deal created, updated, or published — enqueued by API, executed by Worker
- **Payload**: deal_id, merchant_id, deal state, mapped Salesforce CRM fields
- **Consumers**: `salesForce` (external CRM)
- **Guarantees**: at-least-once via Resque retry

### `catalog_update` Detail

- **Topic**: Deal Catalog Service REST API (outbound call from Worker)
- **Trigger**: Deal publish, unpublish, or significant update — enqueued by API, executed by Worker
- **Payload**: deal_id, catalog-formatted deal payload, effective timestamp
- **Consumers**: `continuumDealCatalogService`
- **Guarantees**: at-least-once via Resque retry

## Consumed Events

> No evidence found of DMAPI consuming external event streams or message-bus topics. All inbound triggers arrive via synchronous HTTP requests to the REST API.

## Dead Letter Queues

> No dedicated DLQ configuration was identified in the inventory. Failed Resque jobs are subject to Resque's built-in retry and failure queue mechanisms backed by `continuumDealManagementRedis`.
