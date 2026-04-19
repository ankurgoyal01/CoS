---
service: "inventory_outbound_controller"
title: "Order Fulfillment Import"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "order-fulfillment-import"
flow_type: scheduled
trigger: "Quartz scheduled job fires on configured interval; can also be triggered manually via POST /fulfillment-import-job"
participants:
  - "continuumInventoryOutboundController"
  - "continuumInventoryOutboundControllerDb"
  - "continuumInventoryService"
  - "continuumOrdersService"
  - "continuumDealCatalogService"
  - "messageBus"
architecture_ref: "dynamic-order-fulfillment-import"
---

# Order Fulfillment Import

## Summary

This is the primary batch ingestion flow for converting incoming fulfillment manifests into routed fulfillment records. A Quartz scheduler job fires on a configured schedule, parses pending fulfillment manifests (which may arrive via `POST /fulfillment-manifests` or from an external source), checks inventory eligibility and deal configuration, routes each order to the appropriate fulfillment provider, persists the fulfillment records to MySQL, and publishes a sales order update event to the message bus. It can also be triggered on demand via the admin API.

## Trigger

- **Type**: schedule
- **Source**: Quartz 2.3.0 scheduler within `outboundSchedulingJobs`; manual trigger via `POST /fulfillment-import-job` or `POST /admin/jobs/schedule`
- **Frequency**: Configured schedule (exact cron expression not confirmed from inventory); on-demand via admin API

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Goods Outbound Controller | Orchestrates the entire import flow | `continuumInventoryOutboundController` |
| Outbound Controller DB | Reads pending manifests; persists created fulfillment records | `continuumInventoryOutboundControllerDb` |
| Inventory Service | Provides inventory availability and eligibility data | `continuumInventoryService` |
| Orders Service | Provides order details for manifest line items | `continuumOrdersService` |
| Deal Catalog Service | Provides fulfillment deal configuration and routing rules | `continuumDealCatalogService` |
| Message Bus | Receives published sales order update events | `messageBus` |

## Steps

1. **Quartz job fires**: `outboundSchedulingJobs` triggers the fulfillment import job on schedule (or on manual demand).
   - From: Quartz scheduler (internal to `continuumInventoryOutboundController`)
   - To: `outboundFulfillmentOrchestration`
   - Protocol: direct (in-process)

2. **Fetch pending manifests**: `outboundPersistenceAdapters` reads pending fulfillment manifests from `continuumInventoryOutboundControllerDb`.
   - From: `continuumInventoryOutboundController`
   - To: `continuumInventoryOutboundControllerDb`
   - Protocol: JDBC / MySQL

3. **Parse manifest line items**: `outboundFulfillmentOrchestration` parses each manifest into individual order/line-item fulfillment requests.
   - From: `continuumInventoryOutboundController`
   - To: internal orchestration
   - Protocol: direct

4. **Check inventory eligibility**: For each line item, `outboundExternalServiceClients` queries the Inventory Service to confirm availability.
   - From: `continuumInventoryOutboundController`
   - To: `continuumInventoryService`
   - Protocol: HTTP / REST

5. **Fetch deal fulfillment configuration**: `outboundExternalServiceClients` queries the Deal Catalog Service for routing rules and fulfillment deal config applicable to each deal in the manifest.
   - From: `continuumInventoryOutboundController`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP / REST

6. **Fetch order details**: `outboundExternalServiceClients` queries the Orders Service for order context needed to complete fulfillment routing.
   - From: `continuumInventoryOutboundController`
   - To: `continuumOrdersService`
   - Protocol: HTTP / REST

7. **Route fulfillments**: `outboundFulfillmentOrchestration` applies routing logic (deal config, inventory eligibility, provider availability) to assign each line item to a fulfillment provider.
   - From: internal to `continuumInventoryOutboundController`
   - To: internal
   - Protocol: direct

8. **Persist fulfillment records**: `outboundPersistenceAdapters` writes the new fulfillment records (status: created/routed) to `continuumInventoryOutboundControllerDb`.
   - From: `continuumInventoryOutboundController`
   - To: `continuumInventoryOutboundControllerDb`
   - Protocol: JDBC / MySQL

9. **Publish sales order update event**: `outboundMessagingAdapters` publishes a `jms.topic.goods.salesorder.update` event for each successfully created fulfillment.
   - From: `continuumInventoryOutboundController`
   - To: `messageBus`
   - Protocol: JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Inventory Service unavailable | HTTP call fails; orchestration marks the line item as ineligible or defers | Line item skipped; retry job will reprocess on next run |
| Deal Catalog Service unavailable | HTTP call fails; routing cannot be completed for affected deals | Affected line items deferred; logged for retry |
| Orders Service unavailable | HTTP call fails; order context missing | Affected line items deferred; logged for retry |
| MySQL write failure | Persistence fails; transaction rolled back | Fulfillment not created; will be retried by the scheduled retry/reaper job |
| Message bus publish failure | Event publish fails after fulfillment persisted | Fulfillment record exists in DB; downstream consumers not notified; retry expected |

## Sequence Diagram

```
Quartz -> outboundFulfillmentOrchestration: fire import job
outboundFulfillmentOrchestration -> DB: read pending manifests
DB --> outboundFulfillmentOrchestration: manifest records
outboundFulfillmentOrchestration -> InventoryService: GET eligibility for line items
InventoryService --> outboundFulfillmentOrchestration: eligibility response
outboundFulfillmentOrchestration -> DealCatalogService: GET fulfillment_deal_config
DealCatalogService --> outboundFulfillmentOrchestration: routing config
outboundFulfillmentOrchestration -> OrdersService: GET order details
OrdersService --> outboundFulfillmentOrchestration: order data
outboundFulfillmentOrchestration -> DB: INSERT fulfillment records
DB --> outboundFulfillmentOrchestration: committed
outboundFulfillmentOrchestration -> MessageBus: publish jms.topic.goods.salesorder.update
```

## Related

- Architecture dynamic view: `dynamic-order-fulfillment-import`
- Related flows: [Inventory Update Processing](inventory-update-processing.md), [Scheduled Retry Reaper](scheduled-retry-reaper.md)
