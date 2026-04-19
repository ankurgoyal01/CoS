---
service: "reporting-service"
title: "Payment Event Consumption"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "payment-event-consumption"
flow_type: event-driven
trigger: "MBus PaymentNotification event"
participants:
  - "reportingService_mbusConsumers"
  - "reportGenerationService"
  - "reportingService_persistenceDaos"
  - "continuumReportingDb"
  - "mbus"
architecture_ref: "Reporting-API-Components"
---

# Payment Event Consumption

## Summary

The reporting service consumes `PaymentNotification` events from the Continuum message bus (MBus) to keep merchant reporting data current with payment outcomes. When a payment event arrives, the `reportingService_mbusConsumers` component persists the payment data to the Reporting Database and optionally triggers downstream reporting workflows via `reportGenerationService`, ensuring that deal performance reports reflect up-to-date payment activity.

## Trigger

- **Type**: event
- **Source**: MBus `PaymentNotification` event published by the Continuum payments domain
- **Frequency**: Per payment event; real-time

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBus | Message broker delivering PaymentNotification events | `mbus` |
| MBus Consumers | Receives and processes inbound PaymentNotification events | `reportingService_mbusConsumers` |
| Report Generation | Triggered to update or generate reports reflecting payment data | `reportGenerationService` |
| Persistence Layer | Writes payment event data to the Reporting Database | `reportingService_persistenceDaos` |
| Reporting Database | Stores persisted payment event records | `continuumReportingDb` |

## Steps

1. **Receive PaymentNotification event**: `reportingService_mbusConsumers` receives a `PaymentNotification` event from MBus.
   - From: `mbus`
   - To: `reportingService_mbusConsumers`
   - Protocol: MBus

2. **Validate event payload**: MBus Consumers validates the event structure and extracts deal ID, payment amount, and merchant context.
   - From: `reportingService_mbusConsumers`
   - To: internal validation logic
   - Protocol: direct

3. **Persist payment data**: MBus Consumers writes the payment event record to the Reporting Database via the Persistence Layer.
   - From: `reportingService_mbusConsumers`
   - To: `reportingService_persistenceDaos` → `continuumReportingDb`
   - Protocol: direct / JDBC

4. **Trigger reporting workflow (conditional)**: For payment events that affect pre-computed report summaries, MBus Consumers triggers `reportGenerationService` to update affected reports.
   - From: `reportingService_mbusConsumers`
   - To: `reportGenerationService`
   - Protocol: direct

5. **Execute report update**: `reportGenerationService` reads updated data and re-renders or updates affected report records.
   - From: `reportGenerationService`
   - To: `reportingService_persistenceDaos` → `continuumReportingDb`
   - Protocol: direct / JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Malformed event payload | Validation exception in MBus Consumers | Event dropped or sent to DLQ (DLQ configuration not evidenced; confirm with service owner) |
| Database write failure | Hibernate exception | Payment data not persisted; event may be redelivered by MBus (at-least-once) |
| Report generation trigger failure | Exception in reportGenerationService | Payment data persisted but report not updated until next generation request or scheduled run |

## Sequence Diagram

```
mbus -> reportingService_mbusConsumers: PaymentNotification event
reportingService_mbusConsumers -> reportingService_mbusConsumers: validate payload
reportingService_mbusConsumers -> continuumReportingDb: INSERT payment event record
reportingService_mbusConsumers -> reportGenerationService: triggerReportUpdate(dealId, merchantId)
reportGenerationService -> continuumReportingDb: UPDATE report summaries
reportGenerationService --> reportingService_mbusConsumers: done
```

## Related

- Architecture dynamic view: `Reporting-API-Components`
- Related flows: [Report Generation](report-generation.md), [VAT Invoicing](vat-invoicing.md), [Bulk Redemption Processing](bulk-redemption-processing.md)
