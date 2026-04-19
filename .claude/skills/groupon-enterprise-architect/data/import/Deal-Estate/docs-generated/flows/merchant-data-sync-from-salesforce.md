---
service: "Deal-Estate"
title: "Merchant Data Sync from Salesforce"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-data-sync-from-salesforce"
flow_type: event-driven
trigger: "salesforce.opportunity.*, salesforce.account.*, salesforce.planning_object.*, salesforce.price.*, salesforce.option.* events consumed from message bus"
participants:
  - "continuumDealEstateWorker"
  - "continuumDealEstateMysql"
  - "continuumDealEstateRedis"
  - "salesForce"
architecture_ref: "dynamic-merchant-data-sync-from-salesforce"
---

# Merchant Data Sync from Salesforce

## Summary

Salesforce is the system of record for merchant accounts, deal opportunities, planning objects, prices, and options. This flow consumes Salesforce-originated events from the message bus and applies the resulting data updates to Deal-Estate's local deal records in MySQL. Workers process each event type independently, upsert-writing the relevant fields so that Deal-Estate always reflects the latest merchant and deal data from Salesforce.

## Trigger

- **Type**: event
- **Source**: `salesforce.opportunity.*`, `salesforce.account.*`, `salesforce.planning_object.*`, `salesforce.price.*`, `salesforce.option.*` events on the Groupon message bus, originating from the Salesforce integration layer
- **Frequency**: Per Salesforce data change event (on-demand, event-driven)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Salesforce | Source of truth for merchant and deal opportunity data; publishes events | `salesForce` |
| Deal Estate Workers | Consumes Salesforce events and writes data to MySQL | `continuumDealEstateWorker` |
| Deal Estate MySQL | Updated with synced merchant and deal data | `continuumDealEstateMysql` |
| Deal Estate Redis | Job queue backing store for worker processing | `continuumDealEstateRedis` |

## Steps

1. **Salesforce publishes change event**: A change in Salesforce (opportunity, account, planning object, price, or option) results in an event published to the Groupon message bus under the relevant `salesforce.*` topic.
   - From: `salesForce`
   - To: message bus
   - Protocol: mbus

2. **Worker receives event**: `continuumDealEstateWorker` subscribes to the relevant `salesforce.*` topic and dequeues the event.
   - From: message bus
   - To: `continuumDealEstateWorker`
   - Protocol: mbus / Redis protocol

3. **Identify target deal record**: Worker extracts the relevant deal or option identifier from the event payload and looks up the corresponding local record in MySQL.
   - From: `continuumDealEstateWorker`
   - To: `continuumDealEstateMysql`
   - Protocol: ActiveRecord / SQL

4. **Upsert synced data**: Worker writes the Salesforce-sourced fields (account data, opportunity details, pricing, planning object attributes, option attributes) to the deal record via an upsert-style ActiveRecord write.
   - From: `continuumDealEstateWorker`
   - To: `continuumDealEstateMysql`
   - Protocol: ActiveRecord / SQL

5. **Invalidate or update cache**: Worker invalidates any stale cached deal data in Memcached/Redis after the write.
   - From: `continuumDealEstateWorker`
   - To: `continuumDealEstateRedis`
   - Protocol: Redis protocol

6. **Acknowledge event processing**: Resque job completes; event acknowledged.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Event payload missing required identifiers | Worker logs error; job moved to failed queue | No update applied; manual retry required |
| No matching deal record in MySQL | Worker logs warning; job retried or discarded | Salesforce data not applied; possible timing issue if deal not yet created |
| MySQL write failure | Resque retries job with backoff | Sync lag; data eventually consistent |
| Message bus delivery failure | Message bus retains event; delivery retried | Temporary processing delay |
| Persistent job failure | Job moves to Resque failed queue | Manual retry via Resque Web UI; investigate payload/data issue |

## Sequence Diagram

```
salesForce -> messageBus: publish salesforce.<entity>.<event>
messageBus -> continuumDealEstateWorker: deliver event via Resque consumer
continuumDealEstateWorker -> continuumDealEstateMysql: SELECT deal / option by Salesforce ID
continuumDealEstateWorker -> continuumDealEstateMysql: UPSERT Salesforce fields
continuumDealEstateWorker -> continuumDealEstateRedis: invalidate/refresh cache
continuumDealEstateWorker --> messageBus: acknowledge (job complete)
```

## Related

- Architecture dynamic view: `dynamic-merchant-data-sync-from-salesforce`
- Related flows: [Deal Creation and Import](deal-creation-and-import.md), [Deal State Sync from Catalog](deal-state-sync-from-catalog.md)
