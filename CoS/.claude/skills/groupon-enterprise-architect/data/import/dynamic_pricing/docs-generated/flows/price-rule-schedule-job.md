---
service: "dynamic_pricing"
title: "Price Rule Schedule Job"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "price-rule-schedule-job"
flow_type: scheduled
trigger: "Quartz scheduler trigger or scheduled update worker thread"
participants:
  - "continuumPricingService_quartzJobRunner"
  - "continuumPricingService_scheduledUpdateWorker"
  - "continuumPricingService_pricingDbRepository"
  - "continuumPricingService_priceUpdateWorkflow"
  - "continuumPricingService_mbusPublishers"
  - "continuumPricingDb"
  - "continuumMbusBroker"
architecture_ref: "dynamic-pricing-update-continuumPricingService_priceUpdateWorkflow"
---

# Price Rule Schedule Job

## Summary

This flow covers two related background processes: the Quartz Job Runner emitting price-related events on configured schedules, and the Scheduled Update Worker applying time-based price changes that have been pre-programmed into the pricing database. Both processes run continuously in background threads within the Pricing Service, relying on Quartz job metadata persisted in `continuumPricingDb` for coordination and recovery.

## Trigger

- **Type**: schedule
- **Source**: Internal Quartz scheduler (`continuumPricingService_quartzJobRunner`) and background worker threads (`continuumPricingService_scheduledUpdateWorker`)
- **Frequency**: Configured cadence per job definition; continuous polling for scheduled updates

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Job Runner | Fires scheduled jobs emitting price events on configured cadences | `continuumPricingService_quartzJobRunner` |
| Scheduled Update Worker | Polls DB for due price changes and executes update pipeline | `continuumPricingService_scheduledUpdateWorker` |
| Pricing DB Repository | Provides scheduled price update records and Quartz metadata | `continuumPricingService_pricingDbRepository` |
| Price Update Workflow | Executes the price change pipeline for each scheduled entry | `continuumPricingService_priceUpdateWorkflow` |
| MBus Producers | Publishes price events emitted by Quartz jobs and update workflow | `continuumPricingService_mbusPublishers` |
| Pricing Service DB | Source of scheduled updates; stores Quartz job metadata | `continuumPricingDb` |
| MBus Broker | Receives and distributes emitted price events | `continuumMbusBroker` |

## Steps

### Scheduled Update Worker path

1. **Poll for due updates**: Scheduled Update Worker queries `continuumPricingDb` for price updates with an effective timestamp that has passed.
   - From: `continuumPricingService_scheduledUpdateWorker`
   - To: `continuumPricingService_pricingDbRepository` -> `continuumPricingDb`
   - Protocol: JDBC

2. **Execute price update pipeline**: For each due record, the worker invokes the Price Update Workflow.
   - From: `continuumPricingService_scheduledUpdateWorker`
   - To: `continuumPricingService_priceUpdateWorkflow`
   - Protocol: direct

3. **Persist updated price state**: Workflow writes the new price to `continuumPricingDb` and synchronizes PWA parity.
   - From: `continuumPricingService_priceUpdateWorkflow`
   - To: `continuumPricingDb`
   - Protocol: JDBC

4. **Expire Redis cache entry**: Workflow invalidates the affected PriceSummary in Redis.
   - From: `continuumPricingService_priceUpdateWorkflow`
   - To: `continuumRedisCache`
   - Protocol: Redis

5. **Publish price change events**: Workflow publishes `dynamic.pricing.update` event to MBus.
   - From: `continuumPricingService_mbusPublishers`
   - To: `continuumMbusBroker`
   - Protocol: JMS

### Quartz Job Runner path

1. **Quartz fires configured job**: Quartz scheduler fires a job at its configured trigger time, reading job metadata from `continuumPricingDb`.
   - From: `continuumPricingService_quartzJobRunner`
   - To: `continuumPricingDb` (Quartz JDBC job store)
   - Protocol: JDBC

2. **Emit price event**: Job publishes a price-related event to MBus on the configured cadence.
   - From: `continuumPricingService_quartzJobRunner` -> `continuumPricingService_mbusPublishers`
   - To: `continuumMbusBroker`
   - Protocol: JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Scheduled update worker thread dies | Worker must be restarted (service restart) | Scheduled price changes are delayed until service is restarted |
| DB unavailable when polling | Worker retries or pauses; Quartz recovers from JDBC job store on reconnect | Updates delayed until DB is restored |
| Price update pipeline failure | Transaction rolled back for the failing entry | Entry remains in scheduled state; may be retried on next poll cycle |
| MBus publish failure | Price written but event not sent | Downstream consumers not notified of the scheduled price change |
| Quartz job misfires | Quartz misfire policy applied (depends on job configuration) | Job may be skipped or retried per misfire threshold |

## Sequence Diagram

```
continuumPricingService_scheduledUpdateWorker -> continuumPricingDb: Poll for due scheduled price updates (JDBC)
continuumPricingDb --> continuumPricingService_scheduledUpdateWorker: List of due price updates
continuumPricingService_scheduledUpdateWorker -> continuumPricingService_priceUpdateWorkflow: Execute price update pipeline
continuumPricingService_priceUpdateWorkflow -> continuumPricingDb: Persist new price state (JDBC)
continuumPricingService_priceUpdateWorkflow -> continuumRedisCache: Expire PriceSummary entry (Redis)
continuumPricingService_priceUpdateWorkflow -> continuumMbusBroker: Publish dynamic.pricing.update (JMS)

continuumPricingService_quartzJobRunner -> continuumPricingDb: Read Quartz job metadata (JDBC)
continuumPricingService_quartzJobRunner -> continuumMbusBroker: Emit periodic price event (JMS)
```

## Related

- Architecture dynamic view: `dynamic-pricing-update-continuumPricingService_priceUpdateWorkflow`
- Related flows: [Create Retail Price](create-retail-price.md), [Get Current Price Cache Lookup](get-current-price-cache-lookup.md)
- See [Data Stores](../data-stores.md) for Quartz table details
