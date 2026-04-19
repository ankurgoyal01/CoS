---
service: "voucher-inventory-service"
title: "GDPR Right-To-Forget"
generated: "2026-03-03"
type: flow
flow_name: "gdpr-right-to-forget"
flow_type: event-driven
trigger: "GDPR right-to-forget event from GDPR Service"
participants:
  - "continuumVoucherInventoryMessageBus"
  - "continuumVoucherInventoryWorkers"
  - "continuumVoucherInventoryWorkers_gdprListener"
  - "continuumVoucherInventoryUnitsDb"
  - "continuumVoucherInventoryDb"
architecture_ref: "dynamic-continuum-voucher-inventory"
---

# GDPR Right-To-Forget

## Summary

The GDPR right-to-forget flow processes data anonymization requests for customers exercising their GDPR rights. When the GDPR Service publishes a right-to-forget event, VIS Workers consume it and anonymize all personally identifiable information (PII) associated with the customer across both the product and units databases. This includes voucher unit records, redemption records, and any customer-linked order mapping data.

## Trigger

- **Type**: event
- **Source**: GDPR Service publishes right-to-forget events to ActiveMQ
- **Frequency**: On-demand (per GDPR request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Voucher Inventory Message Bus | Delivers GDPR events | `continuumVoucherInventoryMessageBus` |
| Voucher Inventory Workers | Runs GDPR processing pods | `continuumVoucherInventoryWorkers` |
| GDPR & Right-To-Forget Listener | Consumes and orchestrates PII anonymization | `continuumVoucherInventoryWorkers_gdprListener` |
| Voucher Inventory Units DB | Target for unit and redemption PII anonymization | `continuumVoucherInventoryUnitsDb` |
| Voucher Inventory DB | Target for product-level PII anonymization | `continuumVoucherInventoryDb` |

## Steps

1. **GDPR event published**: The GDPR Service publishes a right-to-forget event to the message bus.
   - From: GDPR Service (external)
   - To: `continuumVoucherInventoryMessageBus`
   - Protocol: JMS topics

2. **Event consumed by listener**: The GDPR & Right-To-Forget Listener picks up the event.
   - From: `continuumVoucherInventoryMessageBus`
   - To: `continuumVoucherInventoryWorkers_gdprListener`
   - Protocol: JMS topics

3. **Identify affected records**: The listener identifies all voucher units, redemptions, and order mappings linked to the customer.
   - From: `continuumVoucherInventoryWorkers_gdprListener`
   - To: `continuumVoucherInventoryUnitsDb`
   - Protocol: MySQL

4. **Anonymize PII in Units DB**: Scrub PII from inventory units, redemption records, and order mappings.
   - From: `continuumVoucherInventoryWorkers_gdprListener`
   - To: `continuumVoucherInventoryUnitsDb`
   - Protocol: MySQL

5. **Anonymize PII in Product DB**: Scrub any customer-linked PII from the product database (consumer contracts, etc.).
   - From: `continuumVoucherInventoryWorkers_gdprListener`
   - To: `continuumVoucherInventoryDb`
   - Protocol: MySQL

6. **Acknowledge completion**: Acknowledge the message on successful processing.
   - From: `continuumVoucherInventoryWorkers_gdprListener`
   - To: `continuumVoucherInventoryMessageBus`
   - Protocol: JMS acknowledgement

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Database write failure | Route to DLQ for retry | Anonymization retried by DLQ Processor |
| Partial anonymization failure | Transaction rollback, route to DLQ | Full re-anonymization on retry (idempotent) |
| Customer records not found | Log info, acknowledge message | No action needed; no PII to anonymize |

## Sequence Diagram

```
GDPR Service -> Message Bus: publish(gdpr.right_to_forget)
Message Bus -> GDPR Listener: deliver(rightToForgetEvent)
GDPR Listener -> Units DB: SELECT records WHERE customer_id = ?
Units DB --> GDPR Listener: affectedRecords[]
GDPR Listener -> Units DB: UPDATE anonymize PII in inventory_units, unit_redemptions
GDPR Listener -> Product DB: UPDATE anonymize PII in consumer_contracts
GDPR Listener -> Message Bus: acknowledge(message)
```

## Related

- Architecture dynamic view: `dynamic-continuum-voucher-inventory`
- Related flows: [Order Status Sync](order-status-sync.md)
