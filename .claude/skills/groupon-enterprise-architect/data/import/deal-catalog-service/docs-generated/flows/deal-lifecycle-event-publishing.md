---
service: "deal-catalog-service"
title: "Deal Lifecycle Event Publishing"
generated: "2026-03-03"
type: flow
flow_name: "deal-lifecycle-event-publishing"
flow_type: asynchronous
trigger: "Deal creation or update in the Catalog"
participants:
  - "dealCatalog_merchandisingService"
  - "dealCatalog_messagePublisher"
  - "messageBus"
  - "continuumMarketingDealService"
architecture_ref: "dynamic-continuum-deal-creation"
---

# Deal Lifecycle Event Publishing

## Summary

When a deal is created or updated in the Deal Catalog, the Merchandising Service triggers the Message Publisher to publish deal lifecycle events to the shared Message Bus (MBus). These asynchronous events notify downstream consumers -- primarily the Marketing Deal Service -- about deal state changes, enabling them to take follow-up actions such as resolving geography, fetching pricing, and verifying inventory.

## Trigger

- **Type**: Event (deal creation or update within the Catalog)
- **Source**: Merchandising Service after processing deal metadata changes
- **Frequency**: On every deal creation or significant update

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchandising Service | Triggers event publication after applying business rules | `dealCatalog_merchandisingService` |
| Message Publisher | Formats and publishes events to MBus | `dealCatalog_messagePublisher` |
| Message Bus (MBus) | Distributes events to subscribed consumers | `messageBus` |
| Marketing Deal Service | Downstream consumer that acts on deal lifecycle events | `continuumMarketingDealService` |

## Steps

1. **Merchandising Service processes deal change**: After a deal is created or updated and merchandising rules are applied, the Merchandising Service determines that a lifecycle event should be published.
   - From: `dealCatalog_merchandisingService`
   - To: `dealCatalog_messagePublisher`
   - Protocol: Direct (in-process)

2. **Message Publisher formats event**: The Message Publisher constructs the deal lifecycle event payload (deal ID, metadata, event type, timestamp).
   - From: `dealCatalog_messagePublisher`
   - To: (internal formatting)
   - Protocol: N/A

3. **Message Publisher writes to MBus**: The event is published to the configured MBus deal lifecycle topic.
   - From: `dealCatalog_messagePublisher`
   - To: `messageBus`
   - Protocol: Async (MBus)

4. **Marketing Deal Service receives event**: The Marketing Deal Service subscribes to deal lifecycle events and initiates its own processing (geography resolution, pricing, inventory verification).
   - From: `messageBus`
   - To: `continuumMarketingDealService`
   - Protocol: Async (MBus consumer)

5. **Deal Catalog notifies MDS directly (creation flow)**: In the deal creation flow, the Deal Catalog Service also directly notifies the Marketing Deal Service of the new deal.
   - From: `continuumDealCatalogService`
   - To: `continuumMarketingDealService`
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MBus broker unavailable | Retry with backoff; log failure | Event delayed or lost; downstream consumers see stale state |
| Message serialization error | Log error; fail the publish attempt | Event not published; investigation required |
| Marketing Deal Service down | MBus retains message for retry (at-least-once) | Event delivered when MDS recovers |

## Sequence Diagram

```
Merchandising Service -> Message Publisher: Publish deal lifecycle event
Message Publisher -> Message Bus: Write event (Async/MBus)
Message Bus -> Marketing Deal Service: Deliver deal lifecycle event
Marketing Deal Service -> Bhuvan Service: Resolve geography
Marketing Deal Service -> Pricing Service: Fetch pricing
Marketing Deal Service -> Goods Inventory: Verify inventory
```

## Related

- Architecture dynamic view: `dynamic-continuum-deal-creation`
- Related flows: [Deal Metadata Ingestion](deal-metadata-ingestion.md), [Node Payload Refresh](node-payload-refresh.md)
